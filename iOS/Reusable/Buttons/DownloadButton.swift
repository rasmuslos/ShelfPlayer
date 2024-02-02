//
//  DownloadButton.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import SPBase
import SPOffline
import SPOfflineExtended

struct DownloadButton: View {
    let item: PlayableItem
    let tint: Bool
    
    let offlineTracker: ItemOfflineTracker
    
    init(item: PlayableItem, tint: Bool = false) {
        self.item = item
        self.tint = tint
        
        offlineTracker = item.offlineTracker
    }
    
    var body: some View {
        switch offlineTracker.status {
            case .none:
                Button {
                    Task {
                        if let episode = item as? Episode {
                            try? await OfflineManager.shared.download(episodeId: episode.id, podcastId: episode.podcastId)
                        } else if let audiobook = item as? Audiobook {
                            try? await OfflineManager.shared.download(audiobookId: audiobook.id)
                        }
                    }
                } label: {
                    Label("download", systemImage: "arrow.down")
                }
                .tint(tint ? .green : .primary)
            case .working:
                Button {
                    if let episode = item as? Episode {
                        OfflineManager.shared.delete(episodeId: episode.id)
                    } else {
                        OfflineManager.shared.delete(audiobookId: item.id)
                    }
                } label: {
                    Label("download.remove", systemImage: "trash")
                        .tint(tint ? .red : .primary)
                }
            case .downloaded:
                HStack {
                    ProgressView()
                    Text("downloading")
                }
        }
    }
}

#Preview {
    DownloadButton(item: Audiobook.fixture)
}
