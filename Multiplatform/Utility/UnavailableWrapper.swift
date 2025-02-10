//
//  UnavailableWrapper.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 22.06.24.
//

import SwiftUI

struct UnavailableWrapper<Content: View>: View {
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        ScrollView {
            ZStack {
                Spacer()
                    .containerRelativeFrame([.horizontal, .vertical])
                
                content()
            }
        }
    }
}
