//
//  MediumPlayButtonStyle.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayback

struct MediumPlayButtonStyle: PlayButtonStyle {
    func makeMenu(configuration: Configuration) -> some View {
        let color = (configuration.background.isLight ?? false) ? Color.white : .black
        
        configuration.content
            .bold()
            .font(.footnote)
            .modify {
                if #available(iOS 26, *) {
                    $0
                        .glassEffect(.regular.interactive().tint(color))
                } else {
                    $0
                        .background(color)
                }
            }
    }
    
    func makeLabel(configuration: Configuration) -> some View {
        configuration.content
            .foregroundStyle((configuration.background.isLight ?? false) ? .black : .white)
            .padding(.vertical, 16)
            .padding(.horizontal, 20)
    }
    
    var tint: Bool {
        false
    }
    var cornerRadius: CGFloat {
        .infinity
    }
    var hideRemainingWhenUnplayed: Bool {
        false
    }
}

#if DEBUG
#Preview {
    VStack {
        PlayButton(item: Audiobook.fixture)
            .playButtonSize(.medium)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(.accent)
    .previewEnvironment()
}
#endif
