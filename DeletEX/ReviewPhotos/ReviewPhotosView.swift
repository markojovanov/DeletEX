//
//  ReviewPhotosView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 13.8.24.
//

import Photos
import SwiftUI
import Vision

struct ReviewPhotosView: View {
    let personImages: [PhotoItem]
    @State private var selectedImages: Set<Int> = []
    @State private var showDeletionSuccessView = false
    @State private var deletionError = false

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(personImages.indices, id: \.self) { index in
                        imageView(for: index)
                    }
                }
                .padding()
            }
            if deletionError {
                DeletionErrorBannerView()
                    .padding(.horizontal)
            }
            Divider()
            HStack {
                Text("\(selectedImages.count) photos selected")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityLabel("\(selectedImages.count) photos selected")
                Spacer()
                Button(action: deleteSelectedImages) {
                    Text("Delete photos")
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.red)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                        .accessibilityLabel("Delete selected photos")
                        .accessibilityHint("Deletes all selected photos")
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        .navigationTitle("Review Photos")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    if selectedImages.count == personImages.count {
                        deselectAllImages()
                    } else {
                        selectAllImages()
                    }
                } label: {
                    Text(selectedImages.count == personImages.count ? "Deselect All" : "Select All")
                }
            }
        }
        .navigate(isActive: $showDeletionSuccessView) {
            SuccessView()
        }
    }

    private func imageView(for index: Int) -> some View {
        Image(uiImage: personImages[index].image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 100, height: 100)
            .clipped()
            .cornerRadius(12)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(selectedImages.contains(index) ? Color.blue.opacity(0.4) : Color.clear)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(selectedImages.contains(index) ? Color.blue : Color.clear, lineWidth: 2)
                    if selectedImages.contains(index) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            )
            .onTapGesture {
                withAnimation {
                    toggleSelection(for: index)
                }
            }
            .padding()
    }

    private func toggleSelection(for index: Int) {
        if selectedImages.contains(index) {
            selectedImages.remove(index)
        } else {
            selectedImages.insert(index)
        }
    }

    private func selectAllImages() {
        selectedImages = Set(personImages.indices)
    }

    private func deselectAllImages() {
        selectedImages.removeAll()
    }

    private func deleteSelectedImages() {
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
}
