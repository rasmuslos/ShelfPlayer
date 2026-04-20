//
//  PlayableItemSwipeActionsModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.10.23.
//

import SwiftUI
import ShelfPlayback

struct PlayableItemSwipeActionsModifier: ViewModifier {
    @Environment(Satellite.self) private var satellite

    private let settings = AppSettings.shared

    let itemID: ItemIdentifier
    let currentDownloadStatus: DownloadStatus?

    private var tintColor: TintColor {
        settings.tintColor
    }

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                QueueButton(itemID: itemID)
                    .labelStyle(.iconOnly)
                    .tint(tintColor.accent)
            }
            .swipeActions(edge: .leading) {
                Button("item.play", systemImage: "play") {
                    satellite.start(itemID)
                }
                .labelStyle(.iconOnly)
                .disabled(satellite.isLoading(observing: itemID))
                .tint(tintColor.color)
            }
            .swipeActions(edge: .trailing) {
                DownloadButton(itemID: itemID, tint: true, initialStatus: currentDownloadStatus)
                    .labelStyle(.iconOnly)
            }
            .swipeActions(edge: .trailing) {
                ProgressButton(itemID: itemID, tint: true)
                    .labelStyle(.iconOnly)
            }
    }
}
