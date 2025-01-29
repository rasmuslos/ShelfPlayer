//
//  ItemLoadLink.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemLoadLink: View {
    @Environment(\.library) private var library
    
    let itemID: ItemIdentifier
    var footer: String? = nil
    
    @ViewBuilder
    private var labelContent: some View {
        Label(itemID.type.label, systemImage: itemID.type.icon)
        
        if let footer {
            Text(footer)
        }
    }
    
    var body: some View {
        if library == nil {
            Button {
                
            } label: {
                labelContent
            }
        } else {
            NavigationLink(destination: ItemLoadView(itemID)) {
                labelContent
            }
        }
    }
}

extension ItemIdentifier.ItemType {
    var label: LocalizedStringKey {
        switch self {
        case .audiobook:
            "audiobook.view"
        case .author:
            "author.view"
        case .series:
            "series.view"
        case .podcast:
            "podcast.view"
        case .episode:
            "episode.view"
        }
    }
    
    var icon: String {
        switch self {
        case .audiobook:
            "book"
        case .author:
            "person"
        case .series:
            "rectangle.grid.2x2"
        case .podcast:
            "rectangle.stack"
        case .episode:
            "play.square.stack"
        }
    }
}
