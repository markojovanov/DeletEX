//
//  ReviewPhotosView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 13.8.24.
//

import SwiftUI

struct ReviewPhotosView: View {
    let images: [UIImage]
    @State private var selectedImages: Set<Int> = []

    var body: some View {
        VStack {
            ScrollView {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 16) {
                    ForEach(images.indices, id: \.self) { index in
                        imageView(for: index)
                    }
                }
                .padding()
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
                    if selectedImages.count == images.count {
                        deselectAllImages()
                    } else {
                        selectAllImages()
                    }
                } label: {
                    Text(selectedImages.count == images.count ? "Deselect All" : "Select All")
                }
            }
        }
    }

    private func imageView(for index: Int) -> some View {
        Image(uiImage: images[index])
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
        selectedImages = Set(images.indices)
    }

    private func deselectAllImages() {
        selectedImages.removeAll()
    }

    private func deleteSelectedImages() {
        // TODO: Add delete logic
    }
}

#Preview {
    ReviewPhotosView(images: [UIImage()])
}
