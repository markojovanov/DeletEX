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
    @StateObject private var viewModel = ScanPhotosViewModel()

    var body: some View {
        VStack {
            if viewModel.isLoading {
                loadingView
            } else if viewModel.faceImages.isEmpty {
                noFaceImagesView
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
        .navigate(isActive: $viewModel.showSelectedImageView) {
            DeleteConfirmationView(personImages: viewModel.selectedPersonImages)
        }
    }

    private var loadingView: some View {
        ProgressView("Scanning Photos...")
            .progressViewStyle(CircularProgressViewStyle())
            .padding()
    }

    private var noFaceImagesView: some View {
        VStack(spacing: 30) {
            Text("We couldn’t find any photos with people in your library.")
                .font(.headline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.top, 20)
            Button(action: viewModel.scanPhotosForFaces) {
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
    }

    private var faceImagesView: some View {
        VStack {
            infoBannerView
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(viewModel.faceImages.indices, id: \.self) { index in
                        Button(action: {
                            Task {
                                await viewModel.onImageSelected(viewModel.faceImages[index])
                            }
                        }) {
                            Image(uiImage: viewModel.faceImages[index].croppedFaceImage)
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

    private var infoBannerView: some View {
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
    }
}

#Preview {
    ScanPhotosView()
}
