//
//  FaceDetectionOptionsViewModel.swift
//  DeletEX
//
//  Created by Marko Jovanov on 27.10.24.
//

import Foundation
import Photos
import UIKit

class FaceDetectionOptionsViewModel: ObservableObject {
    @Published var showNextView = false
    @Published var selectedPhotos: [PhotoItem] = []
    @Published var isPhotoPickerPresented = false

    func didSelectPhotos(_ photos: [PhotoItem]) {
        selectedPhotos = photos
        showNextView = true
    }

    func fetchAllPhotos() async {
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
            ) {
                photoItems.append(PhotoItem(image: image, croppedFaceImage: image, phAsset: asset, forFaceRecognition: false))
            }
        }
        selectedPhotos = photoItems
        showNextView = true
    }

    private func requestImage(for asset: PHAsset, imageManager: PHImageManager, targetSize: CGSize, options: PHImageRequestOptions) async -> UIImage? {
        return await withCheckedContinuation { continuation in
            imageManager.requestImage(for: asset, targetSize: targetSize, contentMode: .default, options: options) { image, _ in
                continuation.resume(returning: image)
            }
        }
    }
}
