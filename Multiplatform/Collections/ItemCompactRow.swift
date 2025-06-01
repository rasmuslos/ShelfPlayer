//
//  AudiobookCompactRow.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.04.25.
//

import SwiftUI
import ShelfPlayback

struct ItemCompactRow: View {
    @Environment(Satellite.self) private var satellite
    
    let itemID: ItemIdentifier
    
    let hideImage: Bool
    let trailingText: Text?
    
    let callback: (() -> Void)?
    
    @State private var item: PlayableItem?
    
    @State private var progress: ProgressTracker
    @State private var download: DownloadStatusTracker
    
    init(itemID: ItemIdentifier, hideImage: Bool = false, trailingText: Text? = nil, callback: (() -> Void)? = nil) {
        self.itemID = itemID
        
        self.hideImage = hideImage
        self.trailingText = trailingText
        
        self.callback = callback
        
        _item = .init(initialValue: nil)
        
        _progress = .init(initialValue: .init(itemID: itemID))
        _download = .init(initialValue: .init(itemID: itemID))
    }
    init(item: PlayableItem, hideImage: Bool = false, trailingText: Text? = nil, callback: (() -> Void)? = nil) {
        self.itemID = item.id
        
        self.hideImage = hideImage
        self.trailingText = trailingText
        
        self.callback = callback
        
        _item = .init(initialValue: item)
        
        _progress = .init(initialValue: .init(itemID: itemID))
        _download = .init(initialValue: .init(itemID: itemID))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Button {
                if let callback {
                    callback()
                } else {
                    satellite.start(itemID)
                }
            } label: {
                HStack(spacing: 8) {
                    if !hideImage {
                        ItemImage(item: item, size: .small)
                            .frame(width: 44)
                    }
                    
                    if let item {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .lineLimit(1)
                                .font(.headline)
                            
                            Group {
                                let authors = item.authors.formatted(.list(type: .and, width: .short))
                                
                                if let episode = item as? Episode, episode.podcastName != authors {
                                    Text(verbatim: "\(episode.podcastName) • \(authors)")
                                } else {
                                    Text(authors)
                                }
                            }
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        }
                    } else {
                        ProgressView()
                            .task {
                                load()
                            }
                    }
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            .disabled(satellite.isLoading(observing: itemID))
            
            Spacer(minLength: 12)
            
            if let trailingText {
                trailingText
            } else if download.status == .downloading {
                DownloadButton(itemID: itemID, progressVisibility: .row)
                    .labelStyle(.iconOnly)
            } else if let progress = progress.progress {
                CircleProgressIndicator(progress: progress)
                    .frame(width: 16)
            } else {
                ProgressView()
                    .scaleEffect(0.75)
            }
        }
        .modifier(PlayableItemSwipeActionsModifier(itemID: itemID))
        .modify {
            if let item {
                $0
                    .modifier(PlayableItemContextMenuModifier(item: item))
            } else {
                $0
            }
        }
        .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
    
    private nonisolated func load() {
        guard itemID.type == .audiobook || itemID.type == .episode else {
            return
        }
        
        Task {
            let item = try? await itemID.resolved as? PlayableItem
            
            await MainActor.withAnimation {
                self.item = item
            }
        }
    }
}

#if DEBUG
#Preview {
    ItemCompactRow(item: Audiobook.fixture)
        .previewEnvironment()
}

#Preview {
    ItemCompactRow(item: Episode.fixture)
        .previewEnvironment()
}
#Preview {
    ItemCompactRow(item: Episode.fixture, hideImage: true)
        .previewEnvironment()
}
#endif
