//
//  ItemLoadLink.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemLoadLink: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.library) private var library
    
    let itemID: ItemIdentifier
    var footer: String? = nil
    
    @ViewBuilder
    private var labelContent: some View {
        Label(itemID.type.viewLabel, systemImage: itemID.type.icon)
        
        if let footer {
            Text(footer)
        }
    }
    
    var body: some View {
        Group {
            if library == nil {
                Button {
                    itemID.navigate()
                } label: {
                    labelContent
                }
            } else {
                NavigationLink(destination: ItemLoadView(itemID)) {
                    labelContent
                }
            }
        }
        .disabled(satellite.isOffline)
    }
}

extension ItemIdentifier.ItemType {
    var viewLabel: LocalizedStringKey {
        switch self {
        case .audiobook:
            "item.view.audiobook"
        case .author:
            "item.view.author"
        case .series:
            "item.view.series"
        case .podcast:
            "item.view.podcast"
        case .episode:
            "item.view.episode"
        }
    }
    var errorLabel: LocalizedStringKey {
        switch self {
        case .audiobook:
            "error.unavailable.audiobook"
        case .author:
            "error.unavailable.author"
        case .series:
            "error.unavailable.series"
        case .podcast:
            "error.unavailable.podcast"
        case .episode:
            "error.unavailable.episode"
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
            "square.stack"
        case .episode:
            "play.square"
        }
    }
}
