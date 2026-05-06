//
//  CompactPlayButtonStyle.swift
//  ShelfPlayer
//

import SwiftUI
import ShelfPlayback

struct CompactPlayButtonStyle: PlayButtonStyle {
    func makeMenu(configuration: Configuration) -> some View {
        let color = RFKVisuals.adjust(configuration.background, saturation: 0, brightness: -0.8)

        configuration.content
            .background {
                GeometryReader { geometry in
                    Rectangle()
                        .fill((configuration.background.isLight ?? false) ? .black : .white)
                        .opacity(0.14)
                        .frame(width: geometry.size.width * (1 - (configuration.progress ?? 0)))
                        .padding(.leading, geometry.size.width * (configuration.progress ?? 0))
                        .animation(.smooth, value: configuration.progress)
                }
            }
            .modify {
                if #available(iOS 26, *) {
                    $0
                        .glassEffect(.regular.interactive().tint(color))
                } else {
                    $0
                        .background { color }
                }
            }
    }

    func makeLabel(configuration: Configuration) -> some View {
        configuration.content
            .font(.subheadline.bold())
            .padding(.vertical, 12)
            .padding(.horizontal, 18)
    }

    var tint: Bool { true }
    var cornerRadius: CGFloat { .infinity }
    var hideRemainingWhenUnplayed: Bool { false }
    var hideLabel: Bool { true }
}

extension PlayButtonStyle where Self == CompactPlayButtonStyle {
    static var compact: CompactPlayButtonStyle { .init() }
}
