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
    let context: Context
    
    @State private var item: Item?
    
    @State private var progress: ProgressTracker?
    @State private var download: DownloadStatusTracker?
    
    init(itemID: ItemIdentifier, context: Context = .unknown) {
        self.itemID = itemID
        self.context = context
        
        _item = .init(initialValue: nil)
        
        if itemID.isPlayable {
            _progress = .init(initialValue: .init(itemID: itemID))
            _download = .init(initialValue: .init(itemID: itemID))
        }
    }
    init(item: Item, context: Context = .unknown) {
        self.itemID = item.id
        self.context = context
        
        _item = .init(initialValue: item)
        
        if itemID.isPlayable {
            _progress = .init(initialValue: .init(itemID: itemID))
            _download = .init(initialValue: .init(itemID: itemID))
        }
    }
    
    private var subtitle: String {
        if let series = item as? Series, series.audiobooks.count > 0 {
            return String(localized: "item.count.audiobooks \(series.audiobooks.count)")
        } else if let person = item as? Person {
            return String(localized: "item.count.audiobooks \(person.bookCount)")
        } else if let podcast = item as? Podcast, let incompleteEpisodeCount = podcast.incompleteEpisodeCount {
            return String(localized: "item.count.episodes.unplayed \(incompleteEpisodeCount)")
        } else if let collection = item as? ItemCollection {
            return String(localized: "item.count \(collection.items.count)")
        }
        
        guard itemID.isPlayable || itemID.type == .podcast, let item else {
            return itemID.type.label
        }
        
        let authors = item.authors.formatted(.list(type: .and, width: .short))
        
        if let episode = item as? Episode, episode.podcastName != authors {
            if authors.isEmpty {
                return episode.podcastName
            } else {
                return "\(episode.podcastName) • \(authors)"
            }
        } else {
            return authors
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Group {
                if !context.isImageHidden {
                    if let collection = item as? ItemCollection, !collection.items.isEmpty {
                        if collection.items.count < 4 {
                            ItemImage(item: collection.items.first, size: .small, cornerRadius: context.imageCornerRadius)
                        } else {
                            VStack(spacing: 0) {
                                HStack(spacing: 0) {
                                    ItemImage(item: collection.items[0], size: .tiny, cornerRadius: 0)
                                    ItemImage(item: collection.items[1], size: .tiny, cornerRadius: 0)
                                }
                                HStack(spacing: 0) {
                                    ItemImage(item: collection.items[collection.items.count - 2], size: .tiny, cornerRadius: 0)
                                    ItemImage(item: collection.items[collection.items.count - 1], size: .tiny, cornerRadius: 0)
                                }
                            }
                            .clipShape(.rect(cornerRadius: context.imageCornerRadius))
                            .universalContentShape(.rect(cornerRadius: context.imageCornerRadius))
                        }
                    } else {
                        ItemImage(itemID: itemID, size: .small, cornerRadius: context.imageCornerRadius)
                    }
                }
            }
            .frame(width: context.imageWidth)
            .padding(.trailing, 8)
            
            if let item {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.name)
                        .lineLimit(1)
                        .font(.headline)
                    
                    Text(subtitle)
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
            
            Spacer(minLength: context.isTrailingContentHidden ? 0 : 8)
            
            if !context.isTrailingContentHidden {
                if download?.status == .downloading {
                    DownloadButton(itemID: itemID, progressVisibility: .row)
                        .labelStyle(.iconOnly)
                } else if let progress = progress?.progress {
                    CircleProgressIndicator(progress: progress, invertColors: download?.status == .completed)
                        .frame(width: 16)
                } else if let podcast = item as? Podcast, let incompleteEpisodeCount = podcast.incompleteEpisodeCount {
                    Text(incompleteEpisodeCount, format: .number)
                        .font(.caption)
                        .fontDesign(.rounded)
                        .foregroundStyle(.secondary)
                } else if itemID.isPlayable {
                    ProgressView()
                        .scaleEffect(0.75)
                }
            }
        }
        .contentShape(.rect)
        .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
    
    private nonisolated func load() {
        Task {
            let item = try? await itemID.resolved
            
            await MainActor.withAnimation {
                self.item = item
            }
        }
    }
    
    enum Context {
        case unknown
        
        case offlineEpisode
        
        case convenienceDownloadPreferences
        
        case author
        case narrator
        
        case bookmark
        case collectionLarge
        case collectionEdit
        
        var isImageHidden: Bool {
            switch self {
                case .offlineEpisode, .narrator: true
                default: false
            }
        }
        var imageWidth: CGFloat {
            switch self {
                case .collectionLarge: 68
                default: 44
            }
        }
        var imageCornerRadius: CGFloat {
            switch self {
                case .narrator, .author: .infinity
                default: 8
            }
        }
        
        var isTrailingContentHidden: Bool {
            switch self {
                case .bookmark, .convenienceDownloadPreferences, .collectionEdit: true
                default: false
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
    ItemCompactRow(item: Episode.fixture, context: .offlineEpisode)
        .previewEnvironment()
}
#endif
