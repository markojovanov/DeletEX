//
//  DeletionErrorBannerView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 17.8.24.
//

import SwiftUI

struct DeletionErrorBannerView: View {
    var body: some View {
        VStack(alignment: .center, spacing: 10) {
            Text("Oops! Something went wrong.")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.top, 10)

            Text("We encountered an issue while trying to delete some of your photos.")
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)

            Text("Please try again later or review the photos manually to ensure everything is deleted as expected.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 20)
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.systemRed.withAlphaComponent(0.1)))
                .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 2)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red, lineWidth: 1)
        )
    }
}

#Preview {
    DeletionErrorBannerView()
}
