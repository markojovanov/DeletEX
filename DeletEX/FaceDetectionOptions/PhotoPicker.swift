//
//  PhotoPicker.swift
//  DeletEX
//
//  Created by Marko Jovanov on 27.10.24.
//

import PhotosUI
import SwiftUI

struct PhotoPickerView: UIViewControllerRepresentable {
    @ObservedObject var viewModel: FaceDetectionOptionsViewModel
    @Environment(\.presentationMode) var presentationMode

    func makeUIViewController(context: Context) -> PHPickerViewController {
        let photoLibrary = PHPhotoLibrary.shared()
        var configuration = PHPickerConfiguration(photoLibrary: photoLibrary)
        configuration.filter = .images
        configuration.selectionLimit = 0
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = context.coordinator
        return picker
    }

    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: PhotoPickerView

        init(_ parent: PhotoPickerView) {
            self.parent = parent
        }

        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            Task {
                var selectedImages: [PhotoItem] = []
                for result in results {
                    if let image = await loadImage(from: result) {
                        selectedImages.append(image)
                    }
                }
                await MainActor.run {
                    self.parent.viewModel.didSelectPhotos(selectedImages)
                    self.parent.presentationMode.wrappedValue.dismiss()
                }
            }
        }

        private func loadImage(from result: PHPickerResult) async -> PhotoItem? {
            // Step 1: Load UIImage
            guard let uiImage = await loadUIImage(from: result) else {
                return nil // Return nil if UIImage fails to load
            }

            // Step 2: Load PHAsset
            guard let phAsset = await loadPHAsset(from: result) else {
                return nil // Return nil if PHAsset fails to load
            }

            // Step 3: Return PhotoItem if both UIImage and PHAsset are available
            return PhotoItem(image: uiImage, croppedFaceImage: uiImage, phAsset: phAsset, forFaceRecognition: false)
        }

        /// Separate async function to load UIImage
        private func loadUIImage(from result: PHPickerResult) async -> UIImage? {
            await withCheckedContinuation { continuation in
                if result.itemProvider.canLoadObject(ofClass: UIImage.self) {
                    result.itemProvider.loadObject(ofClass: UIImage.self) { image, _ in
                        continuation.resume(returning: image as? UIImage)
                    }
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }

        /// Separate async function to load PHAsset
        private func loadPHAsset(from result: PHPickerResult) async -> PHAsset? {
            await withCheckedContinuation { continuation in
                // Load the image item identifier
                if let assetIdentifier = result.assetIdentifier {
                    let fetchResult = PHAsset.fetchAssets(withLocalIdentifiers: [assetIdentifier], options: nil)
                    // Return the first PHAsset found, or nil if not found
                    continuation.resume(returning: fetchResult.firstObject)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
