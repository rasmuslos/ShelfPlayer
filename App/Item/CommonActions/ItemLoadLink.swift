//
//  ItemLoadLink.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayback

struct ItemLoadLink: View {
    @Environment(Satellite.self) private var satellite
    @Environment(OfflineMode.self) private var offlineMode
    @Environment(\.navigationContext) private var navigationContext

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
            if let navigationContext {
                Button {
                    navigationContext.path.append(.itemID(itemID))
                } label: {
                    labelContent
                }
            } else {
                Button {
                    itemID.navigateIsolated()
                } label: {
                    labelContent
                }
            }
        }
        .disabled(offlineMode.isEnabled)
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
