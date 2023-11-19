//
//  DownloadIndicator.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 22.10.23.
//

import SwiftUI
import AudiobooksKit

struct DownloadIndicator: View {
    let item: PlayableItem
    
    var body: some View {
        if item.offline == .downloaded {
            Image(systemName: "arrow.down.circle.fill")
                .font(.caption)
                .foregroundStyle(.secondary)
        } else if item.offline == .working {
            ProgressView()
                .scaleEffect(0.75)
        }
    }
}
