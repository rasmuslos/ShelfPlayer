//
//  AudiobookCompactRow.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.04.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemCompactRow: View {
    @Environment(Satellite.self) private var satellite
    
    let item: PlayableItem
    let callback: () -> Void
    
    @State private var progress: ProgressTracker
    
    init(item: PlayableItem, callback: @escaping () -> Void) {
        self.item = item
        self.callback = callback
        
        _progress = .init(initialValue: .init(itemID: item.id))
    }
    
    var body: some View {
        Button {
            callback()
        } label: {
            HStack(spacing: 8) {
                ItemImage(item: item, size: .small)
                    .frame(width: 44)
                
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
                
                Spacer(minLength: 0)
                
                if let progress = progress.progress {
                    CircleProgressIndicator(progress: progress)
                        .frame(width: 16)
                } else {
                    ProgressView()
                        .scaleEffect(0.75)
                }
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .disabled(satellite.isLoading(observing: item.id))
        .modifier(PlayableItemSwipeActionsModifier(itemID: item.id))
        .modifier(PlayableItemContextMenuModifier(item: item))
        .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
}

#if DEBUG
#Preview {
    ItemCompactRow(item: Audiobook.fixture) {
        
    }
    .previewEnvironment()
}
#Preview {
    ItemCompactRow(item: Episode.fixture) {
        
    }
    .previewEnvironment()
}
#endif
