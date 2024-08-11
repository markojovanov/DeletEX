//
//  NavigationLink+Extension.swift
//  DeletEX
//
//  Created by Marko Jovanov on 11.8.24.
//

import SwiftUI

public extension View {
    @ViewBuilder
    func navigate<Destination: View>(
        isActive: Binding<Bool>,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        background(NavigationLink(destination: destination(),
                                  isActive: isActive,
                                  label: EmptyView.init))
    }
}
