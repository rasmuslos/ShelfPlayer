//
//  DisclosureGroupStyle.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.08.24.
//

import Foundation
import SwiftUI
import ShelfPlayback

struct BetterDisclosureGroupStyle: DisclosureGroupStyle {
    var horizontalLabelPadding: CGFloat = 20
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            Button {
                configuration.isExpanded.toggle()
            } label: {
                HStack(spacing: 0) {
                    configuration.label
                        .font(.headline)
                        .accessibilityAddTraits(.isHeader)
                        .hoverEffect(.lift)
                    
                    Spacer(minLength: 8)
                    
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .rotationEffect(.degrees(configuration.isExpanded ? 0 : -90))
                        .animation(.linear(duration: 0.05), value: configuration.isExpanded)
                        .hoverEffect(.lift)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, horizontalLabelPadding)
            
            configuration.content
                .padding(.top, 8)
                .frame(maxHeight: configuration.isExpanded ? .infinity : 0, alignment: .top)
                .clipped()
                .allowsHitTesting(configuration.isExpanded)
                .accessibilityHidden(!configuration.isExpanded)
        }
    }
}

#Preview {
    ScrollView {
        DisclosureGroup(String("Hello, World!")) {
            LazyVStack {
                ForEach(1..<200) {
                    Text($0.description)
                }
            }
        }
    }
}
