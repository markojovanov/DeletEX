//
//  ScanPhotosView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 11.8.24.
//

import Photos
import SwiftUI
import Vision

struct ScanPhotosView: View {
    @State private var faceImages: [PhotoItem] = []
    @State private var isLoading = false
    @State private var selectedImage: PhotoItem? = nil
    @State private var showSelectedImageView = false
    @State private var areFaceImagesLoaded = false

    var body: some View {
        VStack {
            if isLoading {
                ProgressView("Scanning Photos...")
                    .progressViewStyle(CircularProgressViewStyle())
                    .padding()
            } else if faceImages.isEmpty {
                VStack(spacing: 30) {
                    Text("We couldn’t find any photos with people in your library.")
                        .font(.headline)
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.top, 20)
                    Button(action: scanPhotosForFaces) {
                        Text("Try Again")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                            .shadow(radius: 4)
                    }
                    .padding(.bottom, 20)
                }
            } else {
                VStack {
                    HStack {
                        Image(systemName: "info.circle.fill")
                            .foregroundColor(.white)
                            .font(.system(size: 20, weight: .medium))

                        Text("Select your ex from the photos below to review or delete all related memories.")
                            .font(.system(size: 16))
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.blue.opacity(0.85))
                            .shadow(color: .black.opacity(0.2), radius: 4, x: 0, y: 2)
                    )
                    .padding(.horizontal)
                    .padding(.top, 8)
                    ScrollView {
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                            ForEach(faceImages, id: \.self) { photoItem in
                                Button(action: {
                                    onImageSelected(photoItem)
                                }) {
                                    Image(uiImage: photoItem.image)
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height: 100)
                                        .clipped()
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color.black.opacity(0.3), lineWidth: 1)
                                        )
                                        .shadow(radius: 4)
                                }
                                .buttonStyle(PlainButtonStyle())
                            }
                        }
                        .padding()
                    }
                }
            }
        }
        .navigationTitle("People")
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: scanPhotosForFaces)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    rescanPhotosForFaces()
                } label: {
                    Text("Rescan")
                }
            }
        }
        .navigate(isActive: $showSelectedImageView) {
            if let selectedImage {
                DeleteConfirmationView(personImages: [selectedImage])
            }
        }
    }

    private func onImageSelected(_ photoItem: PhotoItem) {
        selectedImage = photoItem
        showSelectedImageView = true
    }

    private func scanPhotosForFaces() {
        if areFaceImagesLoaded {
            return
        }
        areFaceImagesLoaded = true
        isLoading = true

        let fetchOptions = PHFetchOptions()
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)

        let imageManager = PHImageManager.default()
        let requestOptions = PHImageRequestOptions()
        requestOptions.isSynchronous = true
        requestOptions.deliveryMode = .highQualityFormat

        DispatchQueue.global(qos: .userInitiated).async {
            allPhotos.enumerateObjects { asset, _, _ in
                imageManager.requestImage(for: asset,
                                          targetSize: CGSize(width: 300, height: 300),
                                          contentMode: .aspectFit,
                                          options: requestOptions) { image, _ in
                    guard let image = image, let cgImage = image.cgImage else {
                        return
                    }

                    let request = VNDetectFaceRectanglesRequest { request, _ in
                        if let results = request.results as? [VNFaceObservation], !results.isEmpty {
                            DispatchQueue.main.async {
                                self.faceImages.append(PhotoItem(image: image, phAsset: asset))
                            }
                        }
                    }

                    let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
                    try? handler.perform([request])
                }
            }

            DispatchQueue.main.async {
                // TODO: Sort the people images by face.
                isLoading = false
            }
        }
    }

    private func rescanPhotosForFaces() {
        areFaceImagesLoaded = false
        faceImages = []
        scanPhotosForFaces()
    }
}

#Preview {
    ScanPhotosView()
}
