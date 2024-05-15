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
    let downloadingLabel: Bool
    
    let offlineTracker: ItemOfflineTracker
    
    init(item: PlayableItem, tint: Bool = false, downloadingLabel: Bool = true) {
        self.item = item
        self.tint = tint
        self.downloadingLabel = downloadingLabel
        
        offlineTracker = item.offlineTracker
    }
    
    var body: some View {
        Group {
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
                case .downloaded:
                    Button(role: .destructive) {
                        deleteDownload()
                    } label: {
                        Label("download.remove", systemImage: "xmark")
                    }
                case .working:
                    if downloadingLabel {
                        Button(role: .destructive) {
                            deleteDownload()
                        } label: {
                            Label("download.remove.force", systemImage: "xmark")
                        }
                    } else {
                        DownloadProgressIndicator(itemId: item.id)
                            .frame(width: 19)
                            .padding(.trailing, 15)
                    }
            }
        }
        .modifier(TintModifier(tint: tint, offlineStatus: offlineTracker.status))
    }
    
    @MainActor
    private func deleteDownload() {
        if let episode = item as? Episode {
            OfflineManager.shared.delete(episodeId: episode.id)
        } else {
            OfflineManager.shared.delete(audiobookId: item.id)
        }
    }
}

private struct TintModifier: ViewModifier {
    let tint: Bool
    let offlineStatus: ItemOfflineTracker.OfflineStatus
    
    func body(content: Content) -> some View {
        if tint {
            content
                .tint(offlineStatus == .downloaded ? .red : .green)
        } else {
            content
        }
    }
}

#Preview {
    DownloadButton(item: Audiobook.fixture)
}

#Preview {
    DownloadButton(item: Audiobook.fixture, tint: true)
}

#Preview {
    DownloadButton(item: Audiobook.fixture, downloadingLabel: false)
}

#Preview {
    NavigationStack {
        Text(verbatim: ":)")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    DownloadButton(item: Audiobook.fixture, downloadingLabel: false)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "command.circle.fill")
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Image(systemName: "command.circle.fill")
                }
            }
    }
}
