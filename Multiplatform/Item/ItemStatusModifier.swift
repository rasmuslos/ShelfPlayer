//
//  ItemStatusModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 27.06.25.
//

import SwiftUI
import ShelfPlayback

struct ItemStatusModifier: ViewModifier {
    @Environment(Satellite.self) private var satellite
    
    let itemID: ItemIdentifier
    var cornerRadius = 8
    
    @State private var item: Item?
    
    @State private var progress: ProgressTracker?
    @State private var download: DownloadStatusTracker?
    
    init(itemID: ItemIdentifier, cornerRadius: Int = 8) {
        self.itemID = itemID
        self.cornerRadius = cornerRadius
        
        if itemID.isPlayable {
            _progress = .init(initialValue: .init(itemID: itemID))
            _download = .init(initialValue: .init(itemID: itemID))
        }
    }
    init(item: Item, cornerRadius: Int = 8) {
        self.itemID = item.id
        self.cornerRadius = cornerRadius
        
        _item = .init(initialValue: item)
        
        if itemID.isPlayable {
            _progress = .init(initialValue: .init(itemID: itemID))
            _download = .init(initialValue: .init(itemID: itemID))
        }
    }
    
    private var value: String {
        if let series = item as? Series {
            return String(localized: "item.count.audiobooks \(series.audiobooks.count)")
        } else if let person = item as? Person {
            return String(localized: "item.count.audiobooks \(person.bookCount)")
        } else if let podcast = item as? Podcast, let incompleteEpisodeCount = podcast.incompleteEpisodeCount {
            return String(localized: "item.count.episodes.unplayed \(incompleteEpisodeCount)")
        }
        
        guard let progress = progress?.progress, let status = download?.status else {
            return String(localized: "loading")
        }
        
        var result = "\(progress.formatted(.percent.notation(.compactName)))"
        
        switch status {
            case .downloading:
                result += " " + String(localized: "item.downloading")
            case .completed:
                result += " " + String(localized: "item.downloaded")
            default:
                break
        }
        
        return result
    }
    
    func body(content: Content) -> some View {
        content
            .hoverEffect(.highlight)
            .accessibilityLabel(item?.name ?? String(localized: "loading"))
            .accessibilityValue(value)
            .accessibilityIdentifier(itemID.description)
            .modify {
                if itemID.isPlayable {
                    $0
                        .accessibilityAction(.magicTap) {
                            satellite.start(itemID)
                        }
                        .accessibilityAddTraits([.allowsDirectInteraction, .isButton, .isLink, .startsMediaSession])
                } else {
                    $0
                        .accessibilityAddTraits([.isButton, .isLink])
                }
            }
            .modify {
                if let playableItem = item as? PlayableItem {
                    $0
                        .modifier(PlayableItemContextMenuModifier(item: playableItem))
                } else {
                    $0
                }
            }
            .modify {
                if itemID.isPlayable {
                    $0
                        .modifier(PlayableItemSwipeActionsModifier(itemID: itemID))
                } else {
                    $0
                }
            }
            .onAppear {
                if item == nil {
                    load()
                }
            }
    }
    
    private nonisolated func load() {
        Task {
            let item = try? await itemID.resolved
            
            await MainActor.withAnimation {
                self.item = item
            }
        }
    }
}
