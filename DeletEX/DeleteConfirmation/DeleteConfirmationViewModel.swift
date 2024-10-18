//
//  DeleteConfirmationViewModel.swift
//  DeletEX
//
//  Created by Marko Jovanov on 24.8.24.
//

import Photos

class DeleteConfirmationViewModel: ObservableObject {
    @Published var showReviewView = false
    @Published var showDeletionSuccessView = false
    @Published var deletionError = false
    var personImages: [PhotoItem]
    var selectedImage: PhotoItem

    init(selectedImage: PhotoItem,personImages: [PhotoItem]) {
        self.personImages = personImages
        self.selectedImage = selectedImage
    }

    func onDelete() {
        deletionError = false
        let assetsToDelete = personImages.map { $0.phAsset }
        PHPhotoLibrary.shared().performChanges({
            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
        }) { success, error in
            if success {
                let remainingAssets = assetsToDelete.filter { asset in
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil)
                    return fetchResult.count > 0
                }

                if remainingAssets.isEmpty {
                    print("Successfully deleted all assets.")
                    self.showDeletionSuccessView = true
                } else {
                    print("Some assets could not be deleted.")
                    self.deletionError = true
                }
            } else {
                print("Error deleting assets: \(error?.localizedDescription ?? "Unknown error")")
                self.deletionError = true
            }
        }
    }

    func onReview() {
        showReviewView = true
    }
}
