//
//  DeleteConfirmationViewModel.swift
//  DeletEX
//
//  Created by Marko Jovanov on 24.8.24.
//

import Combine
import Photos

class DeleteConfirmationViewModel: ObservableObject {
    @Published var showReviewView = false
    @Published var showDeletionSuccessView = false
    @Published var deletionError = false
    var personImages: [PhotoItem]

    init(personImages: [PhotoItem]) {
        self.personImages = personImages
    }

    func onDelete() {
        // TODO: Commented out because of testing purposes - uncomment it
        print("onDelete called")
//        deletionError = false
//        let assetsToDelete = personImages.map { $0.phAsset }
//        PHPhotoLibrary.shared().performChanges({
//            PHAssetChangeRequest.deleteAssets(assetsToDelete as NSFastEnumeration)
//        }) { success, error in
//            if success {
//                let remainingAssets = assetsToDelete.filter { asset in
//                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [asset.localIdentifier], options: nil)
//                    return fetchResult.count > 0
//                }
//
//                if remainingAssets.isEmpty {
//                    print("Successfully deleted all the assets.")
//                    self.showDeletionSuccessView = true
//                } else {
//                    print("Some assets could not be deleted.")
//                    self.deletionError = true
//                }
//            } else {
//                print("Error deleting assets: \(error?.localizedDescription ?? "Unknown error")")
//                self.deletionError = true
//            }
//        }
    }

    func onReview() {
        showReviewView = true
    }
}
