//
//  ItemConfigureButton.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 06.08.25.
//

import SwiftUI
import ShelfPlayback

struct ItemConfigureButton: View {
    @Environment(Satellite.self) private var satellite

    let itemID: ItemIdentifier
    
    var body: some View {
        Button("item.configure", systemImage: "gearshape") {
            satellite.present(.configureGrouping(itemID))
        }
    }
}

#if DEBUG
#Preview {
    ItemConfigureButton(itemID: .fixture)
        .previewEnvironment()
}
#endif
