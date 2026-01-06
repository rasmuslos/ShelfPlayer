//
//  ContrastModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 10.07.25.
//

import SwiftUI
import RFNotifications

struct ContrastModifier: ViewModifier {
    @Environment(\.library) private var library
    
    let itemID: ItemIdentifier?
    let cornerRadius: CGFloat
    let configuration: ItemImage.ContrastConfiguration?
    
    private var libraryType: LibraryMediaType? {
        if let itemID {
            switch itemID.type {
                case .audiobook, .narrator, .author, .series: .audiobooks
                case .podcast, .episode, .collection, .playlist: .podcasts
            }
        } else if let library {
            library.id.type
        } else {
            nil
        }
    }
    
    func body(content: Content) -> some View {
        if let configuration {
            switch libraryType {
            case .audiobooks:
                content
                    .secondaryShadow(radius: configuration.shadowRadius, opacity: configuration.shadowOpacity)
            case .podcasts:
                content
                    .overlay {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(.gray.opacity(configuration.borderOpacity), lineWidth: configuration.borderThickness)
                    }
            default:
                content
            }
        } else {
            content
        }
    }
}
