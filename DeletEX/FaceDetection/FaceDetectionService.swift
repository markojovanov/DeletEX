//
//  FaceDetectionService.swift
//  DeletEX
//
//  Created by Marko Jovanov on 17.8.24.
//

import Foundation
import Photos
import Vision

protocol FaceDetectionService {
    func fetchFacePhotos(completion: @escaping ([PhotoItem]) -> Void)
}

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
                                          options: requestOptions) { image, _ in
                    guard let image = image, let cgImage = image.cgImage else {
                        group.leave()
                        return
                    }

                    let request = VNDetectFaceRectanglesRequest { request, _ in
                        if let results = request.results as? [VNFaceObservation], !results.isEmpty {
                            photoItems.append(PhotoItem(image: image, phAsset: asset))
                        }
                        group.leave()
                    }

                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try? handler.perform([request])
                }
            }

            group.notify(queue: .main) {
                completion(photoItems)
            }
        }
    }
}
