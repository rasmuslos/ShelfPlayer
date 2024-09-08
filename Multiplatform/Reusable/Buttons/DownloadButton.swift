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

struct DownloadButton: View {
    let item: PlayableItem
    let tint: Bool
    let downloadingLabel: Bool
    
    @State private var notify = false
    @State private var offlineTracker: ItemOfflineTracker
    
    init(item: PlayableItem, tint: Bool = false, downloadingLabel: Bool = true) {
        self.item = item
        self.tint = tint
        self.downloadingLabel = downloadingLabel
        
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
        Button {
            if offlineTracker.status == .none {
                download()
            } else {
                remove()
            }
        } label: {
            if offlineTracker.status == .working && !downloadingLabel {
                ProgressIndicator()
            } else {
                Label(title, systemImage: icon)
            }
        }
        .sensoryFeedback(.success, trigger: notify)
        .modifier(TintModifier(tint: tint, offlineStatus: offlineTracker.status))
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

private struct TintModifier: ViewModifier {
    let tint: Bool
    let offlineStatus: OfflineManager.OfflineStatus
    
    func body(content: Content) -> some View {
        if tint {
            content
                .tint(offlineStatus == .downloaded ? .red : .green)
        } else {
            content
        }
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
