//
//  Placeholder.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 10.07.25.
//

import SwiftUI
import RFNotifications

struct ImagePlaceholder: View {
    @Environment(\.library) private var library
    
    let itemID: ItemIdentifier?
    let cornerRadius: CGFloat
    
    private var itemIDIcon: String? {
        guard let itemID else {
            return nil
        }
        
        return itemID.type.icon
    }
    private var fallbackIcon: String {
        if let itemID {
            itemID.type.icon
        } else {
            switch library?.type {
            case .audiobooks:
                "book"
            case .podcasts:
                "play.square.stack.fill"
            default:
                "bookmark"
            }
        }
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            ZStack {
                Image(systemName: fallbackIcon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: geometryProxy.size.width / 3)
                    .foregroundStyle(.gray.opacity(0.5))
            }
            .frame(width: geometryProxy.size.width, height: geometryProxy.size.height)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.gray.opacity(0.1))
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
        .universalContentShape(.rect(cornerRadius: cornerRadius))
    }
}
