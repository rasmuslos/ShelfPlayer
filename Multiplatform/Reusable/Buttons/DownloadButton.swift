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
    
    let offlineTracker: ItemOfflineTracker
    
    @State private var hapticFeedback = false
    
    init(item: PlayableItem, tint: Bool = false, downloadingLabel: Bool = true) {
        self.item = item
        self.tint = tint
        self.downloadingLabel = downloadingLabel
        
        offlineTracker = ItemOfflineTracker(item)
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
                            
                            hapticFeedback.toggle()
                        }
                    } label: {
                        Label("download", systemImage: "arrow.down")
                    }
                case .working:
                    if downloadingLabel {
                        Button(role: .destructive) {
                            deleteDownload()
                        } label: {
                            Label("download.remove.force", systemImage: "xmark")
                        }
                    } else {
                        DownloadProgressIndicator(itemId: item.id, small: false)
                            .padding(.trailing, 15)
                    }
                case .downloaded:
                    Button(role: .destructive) {
                        deleteDownload()
                    } label: {
                        Label("download.remove", systemImage: "xmark")
                    }
            }
        }
        .sensoryFeedback(.success, trigger: hapticFeedback)
        .modifier(TintModifier(tint: tint, offlineStatus: offlineTracker.status))
    }
    
    @MainActor
    private func deleteDownload() {
        if let episode = item as? Episode {
            OfflineManager.shared.remove(episodeId: episode.id)
        } else {
            OfflineManager.shared.remove(audiobookId: item.id)
        }
        
        hapticFeedback.toggle()
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
