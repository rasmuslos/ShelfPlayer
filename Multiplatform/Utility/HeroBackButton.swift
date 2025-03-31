//
//  BackButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct HeroBackButton: View {
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
        if presentationMode.wrappedValue.isPresented {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("navigation.back", systemImage: "chevron.left")
                    .labelStyle(.iconOnly)
            }
        }
    }
}
