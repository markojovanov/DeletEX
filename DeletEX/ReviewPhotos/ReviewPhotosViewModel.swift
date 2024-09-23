//
//  ReviewPhotosViewModel.swift
//  DeletEX
//
//  Created by Marko Jovanov on 24.8.24.
//

import Photos

class ReviewPhotosViewModel: ObservableObject {
    @Published var showDeletionSuccessView = false
    @Published var deletionError = false
    @Published var noImagesSelectedError = false
    @Published var selectedImages: Set<Int> = []
    let personImages: [PhotoItem]

    init(personImages: [PhotoItem]) {
        self.personImages = personImages
    }

    func toggleSelection(for index: Int) {
        if selectedImages.contains(index) {
            selectedImages.remove(index)
        } else {
            selectedImages.insert(index)
        }
    }

    func selectAllImages() {
        selectedImages = Set(personImages.indices)
    }

    func deselectAllImages() {
        selectedImages.removeAll()
    }

    func deleteSelectedImages() {
        if selectedImages.isEmpty {
            noImagesSelectedError = true
            return
        }
        deletionError = false
        let assetsToDelete = personImages.enumerated()
            .filter { index, _ in selectedImages.contains(index) }
            .map { $0.element.phAsset }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        }) { success, error in
            if success {
                let remainingAssets = assetsToDelete.filter { asset in
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil)
                    return fetchResult.count > 0
                }

                if remainingAssets.isEmpty {
                    print("Successfully deleted all the selected assets.")
                    self.showDeletionSuccessView = true
                } else {
                    print("Some selected assets could not be deleted.")
                    self.deletionError = true
                }
            } else {
                print("Error deleting selected assets: \(error?.localizedDescription ?? "Unknown error")")
                self.deletionError = true
            }
        }
    }
}
