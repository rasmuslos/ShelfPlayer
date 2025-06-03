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
            configuration.content
                .bold()
                .font(.footnote)
                .background((configuration.background.isLight ?? false) ? .white : .black)
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
        12
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
