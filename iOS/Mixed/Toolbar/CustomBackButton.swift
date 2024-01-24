//
//  BackButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct CustomBackButton: View {
    @Environment(\.presentationMode) var presentationMode
    
    var isLight: Bool? = nil
    var accentColor: Color = .accentColor
    
    @Binding var navigationBarVisible: Bool
    
    var body: some View {
        if presentationMode.wrappedValue.isPresented {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .modifier(FullscreenToolbarModifier(accentColor: accentColor, isLight: isLight, navigationBarVisible: $navigationBarVisible))
            }
        }
    }
}
