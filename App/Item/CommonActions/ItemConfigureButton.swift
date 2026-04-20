//
//  ItemConfigureButton.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 06.08.25.
//

import SwiftUI
import ShelfPlayback

struct ItemConfigureButton: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.namespace) private var namespace

    let itemID: ItemIdentifier

    var body: some View {
        Button("item.configure", systemImage: "gearshape.fill") {
            satellite.present(.configureGrouping(itemID))
        }
        .matchedTransitionSource(id: "configure-grouping", in: namespace!)
    }
}
