//
//  BackButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

internal struct FullscreenBackButton: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var isLight: Bool? = nil
    let isToolbarVisible: Bool
    
    var body: some View {
        if presentationMode.wrappedValue.isPresented {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("back", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
                    .modifier(FullscreenToolbarModifier(isLight: isLight, isToolbarVisible: isToolbarVisible))
            }
        }
    }
}
