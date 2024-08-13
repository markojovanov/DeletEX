//
//  DeleteConfirmationView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 11.8.24.
//

import SwiftUI

struct DeleteConfirmationView: View {
    var personImages: [UIImage]
    @State private var showReviewView = false

    var body: some View {
        VStack(spacing: 30) {
            if let personImage = personImages.first {
                Image(uiImage: personImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 120, height: 120)
                    .clipShape(Circle())
                    .overlay(
                        Circle().stroke(Color.white, lineWidth: 4)
                    )
                    .shadow(radius: 10)
            }

            Text("You've selected \(personImages.count) photos.")
                .font(.title2)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)

            VStack(spacing: 15) {
                Text("Are you sure you want to delete all the selected images?")
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)

                Text("We recommend reviewing them first as the system might make mistakes.")
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 30)

            HStack(spacing: 20) {
                Button(action: {
                    onDelete()
                }) {
                    Text("Delete")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 140, height: 50)
                        .background(Color.red)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                }

                Button(action: {
                    onReview()
                }) {
                    Text("Review")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(width: 140, height: 50)
                        .background(Color.blue)
                        .cornerRadius(25)
                        .shadow(radius: 5)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 10)
        )
        .padding(.horizontal, 20)
        .navigate(isActive: $showReviewView) {
            ReviewPhotosView(images: personImages)
        }
    }

    private func onDelete() {
        // TODO: Implement deletion of images
    }

    private func onReview() {
        showReviewView = true
    }
}

#Preview {
    DeleteConfirmationView(personImages: [UIImage()])
}
