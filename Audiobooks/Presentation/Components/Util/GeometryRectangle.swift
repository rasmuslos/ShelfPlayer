//
//  GeometryRectangle.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI

struct GeometryRectangle: View {
    let treshold: CGFloat
    let backgroundColor: Color?
    @Binding var navigationBarVisible: Bool
    
    var body: some View {
        GeometryReader { reader in
            let offset = reader.frame(in: .global).minY
            
            if let backgroundColor = backgroundColor, offset > 0 {
                Rectangle()
                    .foregroundStyle(backgroundColor)
                    .offset(y: -offset)
                    .frame(height: offset)
            }
            
            Color.clear
                .onChange(of: offset) {
                    navigationBarVisible = offset < treshold
                }
        }
    }
}
