//
//  FaceImagesProcessingService.swift
//  DeletEX
//
//  Created by Marko Jovanov on 17.8.24.
//

import Foundation
import Photos
import UIKit
import Vision

// MARK: - FaceImagesProcessingService

protocol FaceImagesProcessingService {
    func fetchFacePhotos(completion: @escaping ([PhotoItem]) -> Void)
    func matchPersonPhotos(selectedFace: PhotoItem, faceImages: [PhotoItem]) async -> [PhotoItem]
}

// MARK: - FaceImagesProcessingServiceImpl

class FaceImagesProcessingServiceImpl: FaceImagesProcessingService {
    func fetchFacePhotos(completion: @escaping ([PhotoItem]) -> Void) {
        let fetchOptions = PHFetchOptions()
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat

        var photoItems: [PhotoItem] = []

        DispatchQueue.global(qos: .userInitiated).async {
            let group = DispatchGroup()

            allPhotos.enumerateObjects { asset, _, _ in
                group.enter()
                imageManager.requestImage(for: asset,
                                          targetSize: CGSize(width: 300, height: 300),
                                          contentMode: .aspectFit,
                                          options: requestOptions) { [weak self] image, _ in
                    guard let self = self else {
                        group.leave()
                        return
                    }
                    guard let image = image, let cgImage = image.cgImage else {
                        group.leave()
                        return
                    }

                    self.detectFaces(in: cgImage) { faceObservations in
                        if !faceObservations.isEmpty {
                            for observation in faceObservations {
                                if self.assessFaceQuality(faceObservation: observation) {
                                    if let croppedFaceImage = self.cropFaceImage(from: image, faceObservation: observation) {
                                        photoItems.append(PhotoItem(image: image, croppedFaceImage: croppedFaceImage, phAsset: asset))
                                    }
                                }
                            }
                        }
                        group.leave()
                    }
                }
            }

            group.notify(queue: .main) {
                completion(photoItems)
            }
        }
    }

    func matchPersonPhotos(selectedFace: PhotoItem, faceImages: [PhotoItem]) async -> [PhotoItem] {
        let embedding1 = await FaceNet.shared.getFaceEmbedding(image: selectedFace.croppedFaceImage)
        var matchedFaces: [PhotoItem] = []
        for face in faceImages {
            let isMatched = await areSamePerson(embedding1: embedding1, image2: face.croppedFaceImage)
            if isMatched {
                matchedFaces.append(face)
            }
        }
        return matchedFaces
    }

    private func detectFaces(in cgImage: CGImage, completion: @escaping ([VNFaceObservation]) -> Void) {
        let startTime = Date()
        let request = VNDetectFaceRectanglesRequest { request, _ in
            let timeInterval = Date().timeIntervalSince(startTime) * 1000
            print("detectFaces: \(timeInterval) milliseconds")
            completion(request.results as? [VNFaceObservation] ?? [])
        }

        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        do {
            try handler.perform([request])
        } catch {
            print("Failed to perform face detection: \(error)")
            completion([])
        }
    }

    private func cropFaceImage(from image: UIImage, faceObservation: VNFaceObservation) -> UIImage? {
        let boundingBox = faceObservation.boundingBox
        let size = image.size

        var rect = CGRect(
            x: boundingBox.origin.x * size.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * size.height,
            width: boundingBox.width * size.width,
            height: boundingBox.height * size.height
        )

        // Add margin around the face
        let margin: CGFloat = 10.0
        rect = rect.insetBy(dx: -margin, dy: -margin)

        // Ensure the rect doesn't exceed the image bounds
        rect.origin.x = max(rect.origin.x, 0)
        rect.origin.y = max(rect.origin.y, 0)
        rect.size.width = min(rect.size.width, size.width - rect.origin.x)
        rect.size.height = min(rect.size.height, size.height - rect.origin.y)

        guard let cgImage = image.cgImage?.cropping(to: rect) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    private func assessFaceQuality(faceObservation: VNFaceObservation) -> Bool {
        let boundingBox = faceObservation.boundingBox
        let width = boundingBox.width
        let height = boundingBox.height
        if width < 0.1 || height < 0.1 {
            return false
        }
        if let yawValue = faceObservation.yaw as? CGFloat {
            if abs(yawValue) > 30.0 {
                return false
            }
        }
        return true
    }

    private func areSamePerson(embedding1: [Float], image2: UIImage, threshold: Float = 0.95) async -> Bool {
        let startTime = Date()
        let embedding2 = await FaceNet.shared.getFaceEmbedding(image: image2)
        guard !embedding1.isEmpty, !embedding2.isEmpty else { return false }
        let distance = calculateEuclideanDistance(embedding1: embedding1, embedding2: embedding2)
        let isSamePerson = distance < threshold
        let timeInterval = Date().timeIntervalSince(startTime) * 1000
        print("areSamePerson: \(timeInterval) milliseconds")
        return isSamePerson
    }

    private func calculateEuclideanDistance(embedding1: [Float], embedding2: [Float]) -> Float {
        precondition(embedding1.count == embedding2.count, "Embeddings must be of the same size.")
        let normalizedEmbedding1 = normalize(embedding: embedding1)
        let normalizedEmbedding2 = normalize(embedding: embedding2)
        var sum: Float = 0.0
        for i in 0 ..< normalizedEmbedding1.count {
            let diff = normalizedEmbedding1[i] - normalizedEmbedding2[i]
            sum += diff * diff
        }
        return sqrt(sum)
    }

    private func normalize(embedding: [Float]) -> [Float] {
        let norm = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
        return embedding.map { $0 / norm }
    }
}
