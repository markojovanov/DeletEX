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
    @Published var selectedImage: PhotoItem? = nil
    @Published var showSelectedImageView = false

    private let faceDetectionService: FaceDetectionService

    init(faceDetectionService: FaceDetectionService = FaceDetectionServiceImpl()) {
        self.faceDetectionService = faceDetectionService
    }

    func onImageSelected(_ photoItem: PhotoItem) {
        selectedImage = photoItem
        showSelectedImageView = true
    }

    func scanPhotosForFaces() {
        guard !isLoading else { return }
        isLoading = true
        faceDetectionService.fetchFacePhotos { [weak self] photoItems in
            guard let self = self else { return }
            // TODO: Sort picture by people
            self.faceImages = photoItems
            self.isLoading = false
        }
    }

    func rescanPhotosForFaces() {
        faceImages = []
        scanPhotosForFaces()
    }
}
