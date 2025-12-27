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
    
    private var headline: String? {
        var parts = [String]()
        
        if let audiobook = item as? Audiobook {
            if let released = audiobook.released {
                parts.append(released)
            }
            
            
            if audiobook.explicit && audiobook.abridged {
                parts.append("🅴🅰")
            } else if audiobook.explicit {
                parts.append("🅴")
            } else if audiobook.abridged {
                parts.append("🅰")
            }
        } else if let episode = item as? Episode {
            if let releaseDate = episode.releaseDate {
                parts.append(releaseDate.formatted(date: .abbreviated, time: .omitted))
            }
            
            parts.append(episode.duration.formatted(.duration(unitsStyle: .abbreviated, allowedUnits: [.minute, .hour])))
        }
        
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
    private var subtitle: String? {
        var parts = [String]()
        
        if let audiobook = item as? Audiobook {
            if !audiobook.authors.isEmpty {
                parts.append(audiobook.authors.formatted(.list(type: .and, width: .narrow)))
            }
            
            if !audiobook.narrators.isEmpty {
                parts.append(audiobook.narrators.formatted(.list(type: .and, width: .narrow)))
            }
        } else if let series = item as? Series, series.audiobooks.count > 0 {
            parts.append(String(localized: "item.count.audiobooks \(series.audiobooks.count)"))
        } else if let person = item as? Person {
            parts.append(String(localized: "item.count.audiobooks \(person.bookCount)"))
        } else if let collection = item as? ItemCollection {
            if collection.id.type == .collection {
                parts.append(String(localized: "item.count.audiobooks \(collection.items.count)"))
            } else {
                parts.append(String(localized: "item.count \(collection.items.count)"))
            }
        } else if let podcast = item as? Podcast {
            if !podcast.authors.isEmpty {
                parts.append(podcast.authors.formatted(.list(type: .and, width: .narrow)))
            }
            
            if let incompleteEpisodeCount = podcast.incompleteEpisodeCount {
                parts.append(String(localized: "item.count.episodes.unplayed \(incompleteEpisodeCount)"))
            }
        }
        
        return parts.isEmpty ? nil : parts.joined(separator: " • ")
    }
    
    var imageCornerRadius: CGFloat {
        switch itemID.type {
            case .author, .narrator: .infinity
            default: 8
        }
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Group {
                if !context.isImageHidden {
                    if let collection = item as? ItemCollection, !collection.items.isEmpty {
                        if collection.items.count < 4 {
                            ItemImage(item: collection.items.first, size: .small, cornerRadius: imageCornerRadius)
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
                            .clipShape(.rect(cornerRadius: imageCornerRadius))
                            .universalContentShape(.rect(cornerRadius: imageCornerRadius))
                        }
                    } else {
                        ItemImage(itemID: itemID, size: .small, cornerRadius: imageCornerRadius)
                    }
                }
            }
            .frame(width: context.imageWidth)
            .padding(.trailing, 12)
            
            if let item {
                VStack(alignment: .leading, spacing: 2) {
                    if let headline {
                        Text(headline)
                            .lineLimit(1)
                            .font(.caption)
                            .fontDesign(.rounded)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(item.name)
                        .lineLimit(1)
                        .font(.headline)
                    
                    if let subtitle {
                        Text(subtitle)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
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
                default: 64
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

