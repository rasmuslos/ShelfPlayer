//
//  BackButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct FullscreenBackButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    let navigationBarVisible: Bool
    
    var isLight: Bool? = nil
    var accentColor: Color = .accentColor
    
    var body: some View {
        if presentationMode.wrappedValue.isPresented {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .modifier(FullscreenToolbarModifier(navigationBarVisible: navigationBarVisible, isLight: isLight, accentColor: accentColor))
            }
        }
    }
}
