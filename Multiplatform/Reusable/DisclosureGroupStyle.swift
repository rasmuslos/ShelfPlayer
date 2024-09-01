//
//  DisclosureGroupStyle.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.08.24.
//

import Foundation
import SwiftUI

struct BetterDisclosureGroupStyle: DisclosureGroupStyle {
    var horizontalLabelPadding: CGFloat = 0
    
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack {
                    configuration.label
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .rotationEffect(.degrees(configuration.isExpanded ? 0 : -90))
                        .animation(.linear, value: configuration.isExpanded)
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
        }
    }
}
