//
//  PhotoLibraryAccssViewModel.swift
//  DeletEX
//
//  Created by Marko Jovanov on 24.8.24.
//

import Photos
import SwiftUI

class PhotoLibraryAccssViewModel: ObservableObject {
    @Published var showNextView = false
    @Published var showAlert = false
    @Published var hasRequestedAccessBefore = false

    func requestPhotoLibraryAccess() {
        PHPhotoLibrary.requestAuthorization(for: .readWrite) { status in
            DispatchQueue.main.async {
                self.hasRequestedAccessBefore = true
                self.handleAuthorizationStatus(status)
            }
        }
    }

    func checkAuthorizationStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        handleAuthorizationStatus(status)
    }

    func handleAuthorizationStatus(_ status: PHAuthorizationStatus) {
        if status == .authorized || status == .limited {
            showNextView = true
        } else {
            if hasRequestedAccessBefore {
                showAlert = true
            }
        }
    }

    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
}
