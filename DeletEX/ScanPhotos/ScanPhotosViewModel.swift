//
//  ScanPhotosViewModel.swift
//  DeletEX
//
//  Created by Marko Jovanov on 17.8.24.
//

import Foundation

class ScanPhotosViewModel: ObservableObject {
    @Published var faceImages: [PhotoItem] = []
    @Published var isLoading = false
    @Published var selectedPersonImages: [PhotoItem] = []
    @Published var showSelectedImageView = false

    private let faceDetectionService: FaceDetectionService

    init(faceDetectionService: FaceDetectionService = FaceDetectionServiceImpl()) {
        self.faceDetectionService = faceDetectionService
    }

    func onImageSelected(_ photoItem: PhotoItem) {
        isLoading = true
        selectedPersonImages = []
        faceDetectionService.matchPersonPhotos(selectedFace: photoItem, faceImages: faceImages) { personPhotos in
            var existingAssets = Set(self.selectedPersonImages.map { $0.phAsset })
            for item in personPhotos {
                if !existingAssets.contains(item.phAsset) {
                    self.selectedPersonImages.append(item)
                    existingAssets.insert(item.phAsset)
                }
            }
            self.isLoading = false
            self.showSelectedImageView = true
        }
    }

    func scanPhotosForFaces() {
        guard !isLoading else { return }
        isLoading = true
        faceDetectionService.fetchFacePhotos { [weak self] faceImages in
            guard let self = self else { return }
            self.faceImages = faceImages
            self.isLoading = false
        }
    }

    func rescanPhotosForFaces() {
        faceImages = []
        scanPhotosForFaces()
    }
}
