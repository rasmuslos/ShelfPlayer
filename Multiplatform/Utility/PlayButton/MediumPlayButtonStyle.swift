//
//  MediumPlayButtonStyle.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI

struct MediumPlayButtonStyle: PlayButtonStyle {
    func makeMenu(configuration: Configuration) -> some View {
        configuration.content
            .bold()
            .font(.footnote)
            .frame(maxWidth: 280)
            .background((configuration.background.isLight ?? false) ? .white : .black)
    }
    
    func makeLabel(configuration: Configuration) -> some View {
        configuration.content
            .foregroundStyle((configuration.background.isLight ?? false) ? .black : .white)
            .padding(.vertical, 16)
            .padding(.horizontal, 8)
            .frame(maxWidth: .infinity)
    }
    
    var cornerRadius: CGFloat {
        12
    }
    var hideRemainingWhenUnplayed: Bool {
        false
    }
}
