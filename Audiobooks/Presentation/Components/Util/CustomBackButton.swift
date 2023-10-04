//
//  BackButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct CustomBackButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var accentColor: Color = .accentColor
    @Binding var navbarVisible: Bool
    
    var body: some View {
        if presentationMode.wrappedValue.isPresented {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .modifier(FullscreenToolbarModifier(accentColor: accentColor, navbarVisible: $navbarVisible))
            }
        }
    }
}
