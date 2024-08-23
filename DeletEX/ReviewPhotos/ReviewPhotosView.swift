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
}

#Preview {
    ReviewPhotosView(personImages: [PhotoItem(image: UIImage(), phAsset: PHAsset())])
}
