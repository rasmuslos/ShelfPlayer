//
//  BackButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct FullscreenBackButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var isLight: Bool? = nil
    let navigationBarVisible: Bool
    
    var body: some View {
        if presentationMode.wrappedValue.isPresented {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("back", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .modifier(FullscreenToolbarModifier(isLight: isLight, navigationBarVisible: navigationBarVisible))
            }
        }
    }
}
