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

    @MainActor
    func onImageSelected(_ photoItem: PhotoItem) async {
        let startTime = Date()
        isLoading = true
        selectedPersonImages.removeAll()
        let personPhotos = await faceImagesProcessingService.matchPersonPhotos(selectedFace: photoItem, faceImages: faceImages)
        let existingAssets = Set(self.selectedPersonImages.map { $0.phAsset })
        let newPhotos = personPhotos.filter { !existingAssets.contains($0.phAsset) }
        self.selectedPersonImages.append(contentsOf: newPhotos)
        let timeInterval = Date().timeIntervalSince(startTime) * 1000
        print("faceRecognition: \(timeInterval) milliseconds")
        self.isLoading = false
        self.showSelectedImageView = true
    }

    func scanPhotosForFaces() {
        guard !isLoading else { return }
        let startTime = Date()
        isLoading = true
        faceImagesProcessingService.fetchFacePhotos { [weak self] faceImages in
            guard let self = self else { return }
            self.faceImages = faceImages
            self.isLoading = false
            let timeInterval = Date().timeIntervalSince(startTime) * 1000
            print("faceDetection: \(timeInterval) milliseconds")
        }
    }

    func rescanPhotosForFaces() {
        faceImages = []
        scanPhotosForFaces()
    }
}
