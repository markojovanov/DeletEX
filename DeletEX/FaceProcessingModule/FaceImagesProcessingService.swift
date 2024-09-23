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
                            photoItems.append(PhotoItem(
                                image: image,
                                croppedFaceImage: croppedFaceImage,
                                phAsset: asset,
                                forFaceRecognition: isImageSuitableForRecognition(image: image, faceObservation: observation)
                            ))
                        }
                    }
                }
            }
        }
        return photoItems
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

    private func requestImage(for asset: PHAsset, imageManager: PHImageManager, targetSize: CGSize, options: PHImageRequestOptions) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
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
        guard let cgImage = image.cgImage else { return nil }
        let boundingBox = faceObservation.boundingBox
        let imageSize = CGSize(width: cgImage.width, height: cgImage.height)
        var rect = CGRect(
            x: boundingBox.origin.x * imageSize.width,
            y: (1 - boundingBox.origin.y - boundingBox.height) * imageSize.height,
            width: boundingBox.width * imageSize.width,
            height: boundingBox.height * imageSize.height
        )
        let margin: CGFloat = 10.0
        rect = rect.insetBy(dx: -margin, dy: -margin)
        rect.origin.x = max(rect.origin.x, 0)
        rect.origin.y = max(rect.origin.y, 0)
        rect.size.width = min(rect.size.width, imageSize.width - rect.origin.x)
        rect.size.height = min(rect.size.height, imageSize.height - rect.origin.y)
        guard let croppedCGImage = cgImage.cropping(to: rect) else { return nil }
        return UIImage(cgImage: croppedCGImage)
    }

    private func isImageSuitableForRecognition(image: UIImage, faceObservation: VNFaceObservation) -> Bool {
        isImageResolutionGood(image: image) &&
            isFaceOrientationGood(faceObservation: faceObservation) &&
            isImageBrightnessGood(image: image)
    }

    private func isImageResolutionGood(image: UIImage, minResolution: CGSize = CGSize(width: 200, height: 200)) -> Bool {
        image.size.width >= minResolution.width && image.size.height >= minResolution.height
    }

    private func isFaceOrientationGood(faceObservation: VNFaceObservation, maxRoll: CGFloat = 20, maxYaw: CGFloat = 20) -> Bool {
        let yaw = faceObservation.yaw?.doubleValue ?? 0
        let roll = faceObservation.roll?.doubleValue ?? 0
        return abs(yaw * 57.3) < maxYaw && abs(roll * 57.3) < maxRoll
    }

    private func isImageBrightnessGood(image: UIImage, minBrightness: CGFloat = 0.28, maxBrightness: CGFloat = 0.7) -> Bool {
        guard let cgImage = image.cgImage else { return false }
        let ciImage = CIImage(cgImage: cgImage)
        let extentVector = CIVector(x: ciImage.extent.origin.x, y: ciImage.extent.origin.y, z: ciImage.extent.size.width, w: ciImage.extent.size.height)
        let filter = CIFilter(name: "CIAreaAverage", parameters: [kCIInputImageKey: ciImage, kCIInputExtentKey: extentVector])!
        guard let outputImage = filter.outputImage else { return false }
        var bitmap = [UInt8](repeating: 0, count: 4)
        let context = CIContext(options: nil)
        context.render(outputImage, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        let brightness = CGFloat(bitmap[0]) / 255.0
        return brightness >= minBrightness && brightness <= maxBrightness
    }

    private func areSamePerson(embedding1: [Float], image2: UIImage, threshold: Float = 0.9) async -> Bool {
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
