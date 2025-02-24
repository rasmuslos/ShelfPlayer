//
//  LargePlayButtonStyle.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct LargePlayButtonStyle: PlayButtonStyle {
    func makeMenu(configuration: Configuration) -> some View {
        configuration.content
            .background {
                ZStack {
                    RFKVisuals.adjust(configuration.background, saturation: 0, brightness: -0.8)
                        .animation(.smooth, value: configuration.background)
                    
                    GeometryReader { geometry in
                        Rectangle()
                            .fill((configuration.background.isLight ?? false) ? .white : .black)
                            .opacity(0.2)
                            .frame(width: geometry.size.width * (configuration.progress ?? 0))
                            .animation(.smooth, value: configuration.progress)
                    }
                }
            }
    }
    
    func makeLabel(configuration: Configuration) -> some View {
        configuration.content
            .font(.callout)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
    }
    
    var cornerRadius: CGFloat {
        8
    }
    var hideRemainingWhenUnplayed: Bool {
        true
    }
}
