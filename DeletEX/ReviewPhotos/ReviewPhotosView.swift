//
//  ReviewPhotosView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 13.8.24.
//

import Photos
import SwiftUI

struct ReviewPhotosView: View {
    @StateObject private var viewModel: ReviewPhotosViewModel

    init(personImages: [PhotoItem]) {
        _viewModel = StateObject(wrappedValue: ReviewPhotosViewModel(personImages: personImages))
    }

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(viewModel.personImages.indices, id: \.self) { index in
                        imageView(for: index)
                    }
                }
                .padding()
            }
            if viewModel.deletionError {
                DeletionErrorBannerView(isVisible: $viewModel.deletionError)
                    .padding(.horizontal)
            }
            if viewModel.noImagesSelectedError {
                noImagesSelectedBannerView
            }
            Divider()
            HStack {
                Text("\(viewModel.selectedImages.count) photos selected")
                    .font(.headline)
                    .foregroundColor(.primary)
                    .accessibilityLabel("\(viewModel.selectedImages.count) photos selected")
                Spacer()
                Button(action: viewModel.deleteSelectedImages) {
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
                    if viewModel.selectedImages.count == viewModel.personImages.count {
                        viewModel.deselectAllImages()
                    } else {
                        viewModel.selectAllImages()
                    }
                } label: {
                    Text(viewModel.selectedImages.count == viewModel.personImages.count ? "Deselect All" : "Select All")
                }
            }
        }
        .navigate(isActive: $viewModel.showDeletionSuccessView) {
            SuccessView()
        }
    }

    private func imageView(for index: Int) -> some View {
        Image(uiImage: viewModel.personImages[index].image)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: 100, height: 100)
            .clipped()
            .cornerRadius(12)
            .overlay(
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(viewModel.selectedImages.contains(index) ? Color.blue.opacity(0.4) : Color.clear)
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(viewModel.selectedImages.contains(index) ? Color.blue : Color.clear, lineWidth: 2)
                    if viewModel.selectedImages.contains(index) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.white)
                    }
                }
            )
            .onTapGesture {
                withAnimation {
                    viewModel.toggleSelection(for: index)
                }
            }
            .padding()
    }

    private var noImagesSelectedBannerView: some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                Button(action: { viewModel.noImagesSelectedError = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                }
            }

            Text("No Images Selected")
                .font(.headline)
                .foregroundColor(.orange)
                .padding(.bottom, 10)

            Text("You haven't selected any images.")
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)

            Text("Please select the images you want to review or delete.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemOrange.withAlphaComponent(0.1)))
                .shadow(color: Color.orange.opacity(0.3), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.orange, lineWidth: 1)
        )
        .padding(.horizontal)
    }
}

#Preview {
    ReviewPhotosView(personImages: [PhotoItem(image: UIImage(), croppedFaceImage: UIImage(), phAsset: PHAsset())])
}
