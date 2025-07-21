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
    var hoverEffect: HoverEffect?
    
    var isInteractive: Bool
    
    @State private var item: Item?
    
    @State private var progress: ProgressTracker?
    @State private var download: DownloadStatusTracker?
    
    init(itemID: ItemIdentifier, cornerRadius: Int = 8, hoverEffect: HoverEffect? = .highlight, isInteractive: Bool = true) {
        self.itemID = itemID
        self.cornerRadius = cornerRadius
        self.hoverEffect = hoverEffect
        self.isInteractive = isInteractive
        
        if itemID.isPlayable {
            _progress = .init(initialValue: .init(itemID: itemID))
            _download = .init(initialValue: .init(itemID: itemID))
        }
    }
    init(item: Item, cornerRadius: Int = 8, hoverEffect: HoverEffect? = .highlight, isInteractive: Bool = true) {
        self.itemID = item.id
        self.cornerRadius = cornerRadius
        self.hoverEffect = hoverEffect
        self.isInteractive = isInteractive
        
        _item = .init(initialValue: item)
        
        if itemID.isPlayable {
            _progress = .init(initialValue: .init(itemID: itemID))
            _download = .init(initialValue: .init(itemID: itemID))
        }
    }
    
    private var label: String {
        guard let item else {
            return String(localized: "loading")
        }
        
        return "\(item.id.type.label): \(item.name)"
    }
    private var value: String {
        if let series = item as? Series, series.audiobooks.count > 0 {
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
                if !satellite.isOffline {
                    result += " " + String(localized: "item.downloaded")
                }
            default:
                break
        }
        
        return result
    }
    
    func body(content: Content) -> some View {
        content
            .modify {
                if let hoverEffect {
                    $0
                        .hoverEffect(hoverEffect)
                } else {
                    $0
                }
            }
            .accessibilityLabel(label)
            .accessibilityValue(value)
            .accessibilityIdentifier(itemID.description)
            .modify {
                if isInteractive {
                    if itemID.isPlayable {
                        $0
                            .accessibilityAction(.magicTap) {
                                satellite.start(itemID)
                            }
                            .accessibilityAddTraits([.isLink, .startsMediaSession])
                    } else {
                        $0
                            .accessibilityAddTraits([.isLink])
                    }
                } else {
                    $0
                }
            }
            .accessibilityRemoveTraits(.isButton)
            .modify {
                if isInteractive, let playableItem = item as? PlayableItem {
                    $0
                        .modifier(PlayableItemContextMenuModifier(item: playableItem, currentDownloadStatus: download?.status))
                } else {
                    $0
                }
            }
            .modify {
                if isInteractive, itemID.isPlayable {
                    $0
                        .modifier(PlayableItemSwipeActionsModifier(itemID: itemID, currentDownloadStatus: download?.status))
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
