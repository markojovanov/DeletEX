//
//  FaceDetectionService.swift
//  DeletEX
//
//  Created by Marko Jovanov on 17.8.24.
//

import Foundation
import Photos
import UIKit
import Vision

// MARK: - FaceDetectionService

protocol FaceDetectionService {
    func fetchFacePhotos(completion: @escaping ([PhotoItem]) -> Void)
    func groupPhotosByFace(faceImages: [PhotoItem], completion: @escaping ([[PhotoItem]]) -> Void)
}

// MARK: - FaceDetectionServiceImpl

class FaceDetectionServiceImpl: FaceDetectionService {
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
                                if let croppedFaceImage = self.cropFaceImage(from: image, faceObservation: observation) {
                                    photoItems.append(PhotoItem(image: image, croppedFaceImage: croppedFaceImage, phAsset: asset))
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

    func groupPhotosByFace(faceImages: [PhotoItem], completion: @escaping ([[PhotoItem]]) -> Void) {
        // TODO: Create Machine Learning model for face recognition.
        completion(groupPhotoItemsByPairs(faceImages))
    }

    private func detectFaces(in cgImage: CGImage, completion: @escaping ([VNFaceObservation]) -> Void) {
        let request = VNDetectFaceRectanglesRequest { request, _ in
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

    private func groupPhotoItemsByPairs(_ photoItems: [PhotoItem]) -> [[PhotoItem]] {
        return stride(from: 0, to: photoItems.count, by: 2).map { index in
            Array(photoItems[index ..< min(index + 2, photoItems.count)])
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
}
