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

    private let faceImagesProcessingService: FaceImagesProcessingService

    init(faceImagesProcessingService: FaceImagesProcessingService = FaceImagesProcessingServiceImpl()) {
        self.faceImagesProcessingService = faceImagesProcessingService
    }

    func onImageSelected(_ photoItem: PhotoItem) {
        isLoading = true
        selectedPersonImages.removeAll()
        faceImagesProcessingService.matchPersonPhotos(selectedFace: photoItem, faceImages: faceImages) { [weak self] personPhotos in
            guard let self = self else { return }
            let existingAssets = Set(self.selectedPersonImages.map { $0.phAsset })
            let newPhotos = personPhotos.filter { !existingAssets.contains($0.phAsset) }
            self.selectedPersonImages.append(contentsOf: newPhotos)
            self.isLoading = false
            self.showSelectedImageView = true
        }
    }

    func scanPhotosForFaces() {
        guard !isLoading else { return }
        isLoading = true
        faceImagesProcessingService.fetchFacePhotos { [weak self] faceImages in
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
