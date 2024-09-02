//
//  GeometryRectangle.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI

struct FullscreenBackground: View {
    let threshold: CGFloat
    let backgroundColor: Color?
    
    @Binding var navigationBarVisible: Bool
    
    var body: some View {
        GeometryReader { reader in
            let offset = reader.frame(in: .global).minY
            
            if offset > 0 {
                Rectangle()
                    .fill(backgroundColor ?? Color(UIColor.tertiarySystemBackground))
                    .animation(.smooth, value: backgroundColor)
                    .offset(y: -offset)
                    .frame(height: offset)
            }
            
            Color.clear
                .frame(width: 0, height: 0)
                .onChange(of: offset) {
                    withAnimation(.spring) {
                        navigationBarVisible = offset < threshold
                    }
                }
        }
    }
}
