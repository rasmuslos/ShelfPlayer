//
//  DownloadButton.swift
//  iOS
//
//  Created by Rasmus Krämer on 02.02.24.
//

import SwiftUI
import SPFoundation
import SPOffline
import SPOfflineExtended

internal struct DownloadButton: View {
    let item: PlayableItem
    let tint: Bool
    let downloadingLabel: Bool
    let progressIndicator: Bool
    
    @State private var notify = false
    @State private var offlineTracker: ItemOfflineTracker
    
    init(item: PlayableItem, tint: Bool = false, downloadingLabel: Bool = true, progressIndicator: Bool = false) {
        self.item = item
        self.tint = tint
        self.downloadingLabel = downloadingLabel
        self.progressIndicator = progressIndicator
        
        _offlineTracker = .init(initialValue: .init(item))
    }
    
    private var title: LocalizedStringKey {
        switch offlineTracker.status {
            case .none:
                "download"
            case .working:
                "download.remove.force"
            case .downloaded:
                "download.remove"
        }
    }
    private var icon: String {
        switch offlineTracker.status {
            case .none:
                "arrow.down"
            default:
                "xmark"
        }
    }
    
    var body: some View {
        Button(role: offlineTracker.status == .none || tint ? nil : .destructive) {
            if offlineTracker.status == .none {
                download()
            } else {
                remove()
            }
        } label: {
            if offlineTracker.status == .working && progressIndicator {
                DownloadProgressIndicator(itemId: item.id, small: false)
            } else if offlineTracker.status == .working && !downloadingLabel {
                ProgressIndicator()
            } else {
                Label(title, systemImage: icon)
            }
        }
        .sensoryFeedback(.success, trigger: notify)
        .symbolVariant(tint ? .none : .circle)
        .tint(tint ? .blue : nil)
    }
    
    private func download() {
        Task {
            let identifiers = item.identifiers
            
            if let episodeID = identifiers.episodeID {
                try? await OfflineManager.shared.download(episodeId: episodeID, podcastId: identifiers.itemID)
            } else {
                try? await OfflineManager.shared.download(audiobookId: identifiers.itemID)
            }
            
            notify.toggle()
        }
    }
    
    private func remove() {
        let identifiers = item.identifiers
        
        if let episodeID = identifiers.episodeID {
            OfflineManager.shared.remove(episodeId: episodeID)
        } else {
            OfflineManager.shared.remove(audiobookId: identifiers.itemID)
        }
        
        notify.toggle()
    }
}

#if DEBUG
#Preview {
    DownloadButton(item: Audiobook.fixture)
}

#Preview {
    DownloadButton(item: Audiobook.fixture, tint: true)
}

#Preview {
    DownloadButton(item: Audiobook.fixture, downloadingLabel: false)
}
#endif
