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
    func fetchFacePhotos() async -> [PhotoItem]
    func matchPersonPhotos(selectedFace: PhotoItem, faceImages: [PhotoItem]) async -> [PhotoItem]
}

// MARK: - FaceImagesProcessingServiceImpl

class FaceImagesProcessingServiceImpl: FaceImagesProcessingService {
    func fetchFacePhotos() async -> [PhotoItem] {
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat
        requestOptions.resizeMode = .exact
        var photoItems: [PhotoItem] = []

        for index in 0 ..< allPhotos.count {
            let asset = allPhotos.object(at: index)
            if let image = await requestImage(
                for: asset,
                imageManager: imageManager,
                targetSize: CGSize(width: 400, height: 550),
                options: requestOptions
            ),
                let cgImage = image.cgImage {
                let faceObservations = await detectFaces(in: cgImage)
                if !faceObservations.isEmpty {
                    for observation in faceObservations {
                        if let croppedFaceImage = cropFaceImage(from: image, faceObservation: observation) {
                            photoItems.append(PhotoItem(image: image, croppedFaceImage: croppedFaceImage, phAsset: asset))
                        }
                    }
                }
            }
        }
        return photoItems
    }

    private func requestImage(for asset: PHAsset, imageManager: PHImageManager, targetSize: CGSize, options: PHImageRequestOptions) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options) { image, _ in
                continuation.resume(returning: image)
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

    private func detectFaces(in cgImage: CGImage) async -> [VNFaceObservation] {
        let startTime = Date()

        return await withCheckedContinuation { continuation in
            let request = VNDetectFaceRectanglesRequest { request, _ in
                let timeInterval = Date().timeIntervalSince(startTime) * 1000
                print("detectFaces: \(timeInterval) milliseconds")
                let results = request.results as? [VNFaceObservation] ?? []
                continuation.resume(returning: results)
            }

            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                print("Failed to perform face detection: \(error)")
                continuation.resume(returning: [])
            }
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

    private func areSamePerson(embedding1: [Float], image2: UIImage, threshold: Float = 0.95) async -> Bool {
        let startTime = Date()
        let embedding2 = await FaceNet.shared.getFaceEmbedding(image: image2)
        guard !embedding1.isEmpty, !embedding2.isEmpty else {
            return false
        }
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
