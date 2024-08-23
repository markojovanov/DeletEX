//
//  DeleteConfirmationView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 11.8.24.
//

import Photos
import SwiftUI
import Vision

struct DeleteConfirmationView: View {
    var personImages: [PhotoItem]
    @State private var showReviewView = false
    @State private var showDeletionSuccessView = false
    @State private var deletionError = false

    var body: some View {
        VStack(spacing: 30) {
            if let personImage = personImages.first {
                Image(uiImage: personImage.image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(radius: 10)
            }

            Text("You've selected \(personImages.count) photos.")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            VStack(spacing: 15) {
                Text("Are you sure you want to delete all the selected images?")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text("We recommend reviewing them first as the system might make mistakes.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 30)
            if deletionError {
                DeletionErrorBannerView()
            }
            HStack(spacing: 20) {
                Button(action: {
                    onDelete()
                }) {
                    Text("Delete")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 140, height: 50)
                        .background(Color.red)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                }

                Button(action: {
                    onReview()
                }) {
                    Text("Review")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 140, height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 10)
        )
        .padding(.horizontal, 20)
        .navigate(isActive: $showReviewView) {
            ReviewPhotosView(personImages: personImages)
        }
        .navigate(isActive: $showDeletionSuccessView) {
            SuccessView()
        }
    }

    private func onDelete() {
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
                    print("Successfully deleted all the assets.")
                    showDeletionSuccessView = true
                } else {
                    print("Some assets could not be deleted.")
                    deletionError = true
                }
            } else {
                print("Error deleting assets: \(error?.localizedDescription ?? "Unknown error")")
                deletionError = true
            }
        }
    }

    private func onReview() {
        showReviewView = true
    }
}

