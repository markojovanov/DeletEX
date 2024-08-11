//
//  ContentView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 6.7.24.
//

import Photos
import SwiftUI

struct ContentView: View {
    @State private var showNextView = false
    @State private var showAlert = false
    @State private var hasRequestedAccessBefore = false
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                Image(systemName: "photo.on.rectangle.angled")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 100, height: 100)
                    .foregroundColor(.blue)

                Text("Access Required")
                    .font(.largeTitle)
                    .fontWeight(.semibold)

                Text("This app needs access to your photo library to process and manage your images. You can delete photos after processing them.")
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .foregroundColor(.secondary)

                Button(action: requestPhotoLibraryAccess) {
                    HStack {
                        Image(systemName: "lock.open.fill")
                            .font(.headline)
                        Text("Give Access")
                            .font(.headline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal, 40)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.systemGray6))
                    .shadow(radius: 10)
            )
            .padding()
            .navigationBarTitleDisplayMode(.inline)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text("Access Denied"),
                    message: Text("Without photo library access, the app cannot process your images. You can enable access in Settings."),
                    primaryButton: .default(Text("Open Settings"), action: openAppSettings),
                    secondaryButton: .cancel(Text("Cancel"))
                )
            }
            .navigate(isActive: $showNextView) {
                ScanPhotosView()
            }
            .onChange(of: scenePhase) { newPhase in
                if newPhase == .active {
                    checkAuthorizationStatus()
                }
            }
        }
    }

    private func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                hasRequestedAccessBefore = true
                handleAuthorizationStatus(status)
            }
        }
    }

    private func checkAuthorizationStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        handleAuthorizationStatus(status)
    }

    private func handleAuthorizationStatus(_ status: PHAuthorizationStatus) {
        if status == .authorized {
            showNextView = true
        } else {
            if hasRequestedAccessBefore {
                showAlert = true
            }
        }
    }

    private func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}

#Preview {
    ContentView()
}
