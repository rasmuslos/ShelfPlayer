//
//  DownloadIndicator.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 22.10.23.
//

import SwiftUI
import SPBaseKit
import SPOfflineExtendedKit

struct DownloadIndicator: View {
    let offlineTracker: ItemOfflineTracker
    
    init(item: PlayableItem) {
        offlineTracker = item.offlineTracker
    }
    
    var body: some View {
        if offlineTracker.status == .downloaded {
            Image(systemName: "arrow.down.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if offlineTracker.status == .working {
            ProgressView()
                .scaleEffect(0.75)
        }
    }
}
