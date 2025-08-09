//
//  ItemLoadLink.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayback

struct ItemLoadLink: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.library) private var library
    
    let itemID: ItemIdentifier
    var footer: String? = nil
    
    @ViewBuilder
    private var labelContent: some View {
        if #available(iOS 26.0, *), false {
            if let footer {
                Label(footer, systemImage: itemID.type.icon)
            } else {
                Label(itemID.type.viewLabel, systemImage: itemID.type.icon)
            }
        } else {
            Label(itemID.type.viewLabel, systemImage: itemID.type.icon)
            
            if let footer {
                Text(footer)
            }
        }
    }
    
    var body: some View {
        Group {
            if library == nil {
                Button {
                    itemID.navigateIsolated()
                } label: {
                    labelContent
                }
            } else {
                NavigationLink(value: NavigationDestination.itemID(itemID)) {
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
            case .narrator:
                "item.view.narrator"
            case .series:
                "item.view.series"
            case .podcast:
                "item.view.podcast"
            case .episode:
                "item.view.episode"
            case .collection:
                "item.view.collection"
            case .playlist:
                "item.view.playlist"
        }
    }
    var errorLabel: LocalizedStringKey {
        switch self {
            case .audiobook:
                "error.unavailable.audiobook"
            case .author:
                "error.unavailable.author"
            case .narrator:
                "error.unavailable.narrator"
            case .series:
                "error.unavailable.series"
            case .podcast:
                "error.unavailable.podcast"
            case .episode:
                "error.unavailable.episode"
            case .collection:
                "error.unavailable.collection"
            case .playlist:
                "error.unavailable.playlist"
        }
    }
}
