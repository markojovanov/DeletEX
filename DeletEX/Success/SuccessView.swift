//
//  SuccessView.swift
//  DeletEX
//
//  Created by Marko Jovanov on 16.8.24.
//

import SwiftUI

struct SuccessView: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 120, height: 120)
                .foregroundColor(.green)
                .shadow(color: .green.opacity(0.4), radius: 10, x: 0, y: 5)
            Text("All related photos are deleted!")
                .multilineTextAlignment(.center)
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)
                .shadow(radius: 1)
            Text("Congratulations, you just took a big step in improving your mental health.")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
            Image("text_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 160)
                .foregroundColor(.white)
                .padding(.bottom, 60)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.primaryBackground)
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SuccessView()
}
