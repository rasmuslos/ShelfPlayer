//
//  PlayableItemLinks.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 21.03.25.
//

import SwiftUI
import ShelfPlayback

struct PlayableItemContextMenuModifier: ViewModifier {
    let item: PlayableItem
    let currentDownloadStatus: DownloadStatus?
    
    func body(content: Content) -> some View {
        content
            .contextMenu {
                PlayableItemContextMenuInner(item: item, currentDownloadStatus: currentDownloadStatus)
            } preview: {
                PlayableItemContextMenuPreview(item: item)
            }
    }
}

struct PlayableItemContextMenuInner: View {
    @Environment(\.library) private var library
    
    let item: PlayableItem
    let currentDownloadStatus: DownloadStatus?
    
    var body: some View {
        ItemShareButton(item: item)
        
        Divider()
        
        QueuePlayButton(itemID: item.id)
        QueueButton(itemID: item.id)
        
        Divider()
        
        DownloadButton(itemID: item.id, initialStatus: currentDownloadStatus)
        ItemCollectionMembershipEditButton(itemID: item.id)
        
        Divider()
        
        if let audiobook = item as? Audiobook {
            if library != nil {
                NavigationLink(value: NavigationDestination.item(audiobook)) {
                    Label(ItemIdentifier.ItemType.audiobook.viewLabel, systemImage: "book")
                }
                
                ItemMenu(authors: audiobook.authors)
                ItemMenu(narrators: audiobook.narrators)
            } else {
                ItemLoadLink(itemID: item.id)
                
                // ItemMenu(authors: audiobook.authors)
                ItemMenu(narrators: audiobook.narrators.map { (Person.convertNarratorToID($0, libraryID: item.id.libraryID, connectionID: item.id.connectionID), $0) })
            }
            
            ItemMenu(series: audiobook.series)
        } else if let episode = item as? Episode {
            ItemLoadLink(itemID: episode.id)
            ItemLoadLink(itemID: episode.podcastID)
        }
        
        Divider()
        
        ProgressButton(itemID: item.id)
        ProgressResetButton(itemID: item.id)
    }
}
struct PlayableItemContextMenuPreview: View {
    let item: PlayableItem
    
    var body: some View {
        if let audiobook = item as? Audiobook {
            VStack(alignment: .leading, spacing: 2) {
                ItemProgressIndicatorImage(itemID: audiobook.id, size: .regular, aspectRatio: .none)
                    .padding(.bottom, 12)
                
                Text(audiobook.name)
                    .font(.headline)
                    .modifier(SerifModifier())
                
                if let subtitle = audiobook.subtitle {
                    Text(subtitle)
                        .font(.caption)
                }
                
                if !audiobook.authors.isEmpty {
                    Text(audiobook.authors, format: .list(type: .and, width: .short))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                
                if !audiobook.narrators.isEmpty {
                    Text("item.readBy \(audiobook.narrators.formatted(.list(type: .and, width: .short)))")
                        .font(.subheadline)
                        .foregroundStyle(.tertiary)
                }
            }
            .frame(width: 240)
            .padding(20)
        } else if let episode = item as? Episode {
            VStack(alignment: .leading, spacing: 4) {
                ItemImage(item: episode, size: .regular)
                    .frame(width: 50, height: 50)
                
                Group {
                    let durationText = Text(episode.duration, format: .duration)
                    
                    if let releaseDate = episode.releaseDate {
                        Text(releaseDate, style: .date)
                        + Text(verbatim: " • ")
                        + durationText
                    } else {
                        durationText
                    }
                }
                .font(.caption.smallCaps())
                .foregroundStyle(.secondary)
                .padding(.top, 8)
                
                Text(episode.name)
                    .font(.headline)
                
                Text(episode.podcastName)
                    .lineLimit(1)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                
                if let descriptionText = episode.descriptionText {
                    Text(descriptionText)
                        .padding(.top, 4)
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .compositingGroup()
            .geometryGroup()
            .frame(minWidth: 250, idealWidth: 400, maxHeight: 500)
        }
    }
}

#if DEBUG
#Preview {
    PlayableItemContextMenuPreview(item: Audiobook.fixture)
}
#Preview {
    PlayableItemContextMenuPreview(item: Episode.fixture)
}

#Preview {
    Rectangle()
        .fill(.red)
        .frame(width: 250, height: 500)
}
#endif
