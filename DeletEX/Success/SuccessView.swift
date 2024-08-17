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
            Text("All Photos Deleted!")
                .font(.system(size: 34, weight: .bold))
                .foregroundColor(.primary)
                .shadow(radius: 1)
            Text("You’ve just taken a big step in improving your mental health. 🌟")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(LinearGradient(
            gradient: Gradient(colors: [.white, .green.opacity(0.15)]),
            startPoint: .top, endPoint: .bottom
        )
        .edgesIgnoringSafeArea(.all))
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    SuccessView()
}
