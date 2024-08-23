//
//  TestFaceObservation.swift
//  DeletEX
//
//  Created by Marko Jovanov on 18.8.24.
//

import SwiftUI

// MARK: - TestFaceObservation

struct TestFaceObservation: View {
    @StateObject private var viewModel = TestFaceObservationModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else {
                faceImagesView
            }
        }
        .navigationTitle("People")
        .navigationBarBackButtonHidden(true)
        .onAppear(perform: viewModel.scanPhotosForFaces)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    viewModel.rescanPhotosForFaces()
                } label: {
                    Text("Rescan")
                }
            }
        }
        .sheet(isPresented: $viewModel.showSelectedImageView) {
            if let selectedImage = viewModel.selectedImage {
                ScrollView {
                    ForEach(selectedImage.indices, id: \.self) { index in
                        Image(uiImage: selectedImage[index].image)
                    }
                }
            }
        }
    }

    private var loadingView: some View {
        ProgressView("Scanning Photos...")
            .progressViewStyle(CircularProgressViewStyle())
            .padding()
    }

    private var faceImagesView: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(viewModel.faceImages.indices, id: \.self) { index in
                        Button(action: {
                            viewModel.onImageSelected(viewModel.faceImages[index])
                        }) {
                            if let image = viewModel.faceImages[index].first?.image {
                                Image(uiImage: image)
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
                            } else {
                                Text("3")
                            }
                        }

                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding()
            }
        }
    }
}

#Preview {
    ScanPhotosView()
}

// MARK: - TestFaceObservationModel

class TestFaceObservationModel: ObservableObject {
    @Published var faceImages: [[PhotoItem]] = [[]]
    @Published var isLoading = false
    @Published var selectedImage: [PhotoItem]? = nil
    @Published var showSelectedImageView = false

    private let faceDetectionService: FaceDetectionService

    init(faceDetectionService: FaceDetectionService = FaceDetectionServiceImpl()) {
        self.faceDetectionService = faceDetectionService
    }

    func onImageSelected(_ photoItem: [PhotoItem]) {
        selectedImage = photoItem
        showSelectedImageView = true
    }

    func scanPhotosForFaces() {
        guard !isLoading else {
            return
        }
        isLoading = true
        faceDetectionService.fetchFacePhotos { [weak self] photoItems in
            guard let self = self else {
                return
            }
            // PhotoItems e lista od site sliki so faci
            //self.faceImages = photoItems
//            faceDetectionService.fetchCroppedFacePhotos(from: photoItems) { cropedFaceImages in
//                self.cropedFaceImages = cropedFaceImages
//                self.isLoading = false
//            }
            faceDetectionService.matchFaces(from: photoItems) { matchedFaceImages in
                self.faceImages = matchedFaceImages
            }
            self.isLoading = false
        }
    }

    func rescanPhotosForFaces() {
        faceImages = []
        scanPhotosForFaces()
    }
}
