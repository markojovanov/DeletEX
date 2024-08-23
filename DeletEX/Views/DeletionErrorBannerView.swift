//
//  DeletionErrorBannerView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 17.8.24.
//

import SwiftUI

struct DeletionErrorBannerView: View {
    @Binding var isVisible: Bool

    var body: some View {
        VStack(alignment: .center) {
            HStack {
                Spacer()
                Button(action: { isVisible = false }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.red)
                        .padding(.horizontal, 5)
                }
            }

            Text("Oops! Something went wrong.")
                .font(.headline)
                .foregroundColor(.red)
                .padding(.bottom, 10)

            Text("We encountered an issue while trying to delete some of your photos.")
                .font(.body)
                .foregroundColor(.primary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 6)

            Text("Please try again later or review the photos manually to ensure everything is deleted as expected.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
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
    DeletionErrorBannerView(isVisible: .constant(false))
}
