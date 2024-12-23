//
//  PhotoLibraryAccessView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 12.8.24.
//

import SwiftUI

struct PhotoLibraryAccessView: View {
    @StateObject private var viewModel = PhotoLibraryAccssViewModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        VStack(spacing: 30) {
            Image(systemName: "photo.on.rectangle.angled")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundColor(.blue)

            Text("Photo library access required")
                .font(.title)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("This app needs access to your photo library to process and manage your images. You can delete photos after processing them.")
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)

            Button(action: viewModel.requestPhotoLibraryAccess) {
                Text("Continue")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            .padding(.horizontal, 40)

            Text("You can change this option later in the Settings app.")
                .font(.footnote)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemGray6))
                .shadow(radius: 10)
        )
        .padding()
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .alert(isPresented: $viewModel.showAlert) {
            Alert(
                title: Text("Access Denied"),
                message: Text("Without photo library access, the app cannot process your images. You can enable access in Settings."),
                primaryButton: .default(Text("Open Settings"), action: viewModel.openAppSettings),
                secondaryButton: .cancel(Text("Cancel"))
            )
        }
        .navigate(isActive: $viewModel.showNextView) {
            FaceDetectionOptionsView()
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                viewModel.checkAuthorizationStatus()
            }
        }
    }
}

#Preview {
    PhotoLibraryAccessView()
}
