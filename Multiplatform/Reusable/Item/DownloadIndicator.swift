//
//  DownloadIndicator.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 22.10.23.
//

import SwiftUI
import SPBase
import SPOfflineExtended

struct DownloadIndicator: View {
    let offlineTracker: ItemOfflineTracker
    
    init(item: PlayableItem) {
        offlineTracker = item.offlineTracker
    }
    
    var body: some View {
        if offlineTracker.status == .downloaded {
            Label("download", systemImage: "arrow.down.circle.fill")
                .labelStyle(.iconOnly)
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if offlineTracker.status == .working {
            ProgressIndicator()
                .scaleEffect(0.75)
        }
    }
}
