//
//  FaceDetectionOptionsView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 26.10.24.
//

import SwiftUI

struct FaceDetectionOptionsView: View {
    @StateObject private var viewModel = FaceDetectionOptionsViewModel()

    var body: some View {
        VStack(alignment: .center) {
            Spacer()
            Text("Welcome")
                .font(.largeTitle)
                .fontWeight(.bold)
                .foregroundColor(.primary)
                .padding(.bottom, 50)
            Text("Let's help you move on")
                .font(.title)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
                .padding(.bottom, 36)
                .multilineTextAlignment(.center)
            Text("Ready to say goodbye to old memories? By selecting just a few photos, we can identify faces in seconds! If you prefer, we can also scan your entire gallery, but keep in mind that this may take a few extra minutes.")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            Spacer()
            Button(action: {
                withAnimation {
                    viewModel.isPhotoPickerPresented = true
                }
            }) {
                HStack {
                    Image(systemName: "photo.on.rectangle")
                        .foregroundColor(.white)
                    Text("Pick a Few Photos")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(14)
            }
            Button(action: {
                Task {
                    await viewModel.fetchAllPhotos()
                }
            }) {
                HStack {
                    Image(systemName: "tray.full")
                        .foregroundColor(.primary)
                    Text("Browse All Memories")
                        .fontWeight(.semibold)
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2))
                .foregroundColor(.primary)
                .cornerRadius(14)
            }
            .padding(.vertical, 10)
        }
        .padding()
        .navigationBarHidden(true)
        .sheet(isPresented: $viewModel.isPhotoPickerPresented) {
            PhotoPickerView(viewModel: viewModel)
        }
        .navigate(isActive: $viewModel.showNextView) {
            ScanPhotosView(viewModel: ScanPhotosViewModel(selectedImages: viewModel.selectedPhotos))
        }
    }
}

#Preview {
    FaceDetectionOptionsView()
}
