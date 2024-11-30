//
//  ScanPhotosViewModel.swift
//  DeletEX
//
//  Created by Marko Jovanov on 17.8.24.
//

import Foundation

class ScanPhotosViewModel: ObservableObject {
    @Published var selectedImages: [PhotoItem]
    @Published var faceImages: [PhotoItem] = []
    @Published var isLoading = false
    @Published var selectedPersonImages: [PhotoItem] = []
    @Published var showSelectedImageView = false
    @Published var loadingText = "Detecting faces..."
    @Published var estimatedTimeLeft = ""
    var selectedPersonImage: PhotoItem?

    private let faceImagesProcessingService: FaceImagesProcessingService

    init(
        faceImagesProcessingService: FaceImagesProcessingService = FaceImagesProcessingServiceImpl(),
        selectedImages: [PhotoItem]
    ) {
        self.faceImagesProcessingService = faceImagesProcessingService
        self.selectedImages = selectedImages
    }

    @MainActor
    func onImageSelected(_ photoItem: PhotoItem) async {
        let startTime = Date()
        loadingText = "Searching for matching faces..."
        isLoading = true
        selectedPersonImage = photoItem
        selectedPersonImages.removeAll()
        calculateEstimatedTime(for: faceImages.count)
        let personPhotos = await faceImagesProcessingService.matchPersonPhotos(selectedFace: photoItem, faceImages: faceImages)
        let existingAssets = Set(selectedPersonImages.map { $0.phAsset })
        let newPhotos = personPhotos.filter { !existingAssets.contains($0.phAsset) }
        selectedPersonImages.append(contentsOf: newPhotos)
        let timeInterval = Date().timeIntervalSince(startTime) * 1000
        print("faceRecognition: \(timeInterval) milliseconds")
        isLoading = false
        showSelectedImageView = true
    }

    @MainActor
    func scanPhotosForFaces() async {
        guard !isLoading else { return }
        loadingText = "Detecting faces..."
        estimatedTimeLeft = ""
        let startTime = Date()
        isLoading = true
        faceImages = await faceImagesProcessingService.detectFacePhotos(photoItems: selectedImages)
        isLoading = false
        let timeInterval = Date().timeIntervalSince(startTime) * 1000
        print("faceDetection: \(timeInterval) milliseconds")
    }

    @MainActor
    func rescanPhotosForFaces() async {
        faceImages = []
        await scanPhotosForFaces()
    }

    private func calculateEstimatedTime(for totalImages: Int) {
        let processingTimePerImage = 0.05
        let totalTime = processingTimePerImage * Double(totalImages)

        if totalTime > 60 {
            var minutes = Int(totalTime) / 60
            let seconds = Int(totalTime) % 60
            minutes = seconds > 30 ? minutes + 1 : minutes
            estimatedTimeLeft = "This will take around \(minutes) minute\(minutes > 1 ? "s" : "")..."
        } else {
            estimatedTimeLeft = "This will take around \(totalTime) second\(totalTime != 1 ? "s" : "")..."
        }
    }
}
