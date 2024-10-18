//
//  ContentView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 6.7.24.
//

import Photos
import SwiftUI

struct ContentView: View {
    @State private var showRequestLibraryAccessView = false
    @State private var showScanPhotosView = false

    var body: some View {
        NavigationView {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(2)
                .padding()
                .onAppear { checkAuthorizationStatus() }
                .navigate(isActive: $showRequestLibraryAccessView) {
                    PhotoLibraryAccessView()
                }
                .navigate(isActive: $showScanPhotosView) {
                    ScanPhotosView()
                }
        }
    }

    private func checkAuthorizationStatus() {
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        if status == .authorized || status == .limited {
            showScanPhotosView = true
        } else {
            showRequestLibraryAccessView = true
        }
    }
}

#Preview {
    ContentView()
}
