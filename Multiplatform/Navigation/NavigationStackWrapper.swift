//
//  NavigationSTackWrapper.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 11.01.25.
//

import SwiftUI
import ShelfPlayback

struct NavigationStackWrapper<Content: View>: View {
    let tab: TabValue
    
    @ViewBuilder var content: () -> Content
    
    @State private var path = [NavigationDestination]()
    
    var body: some View {
        NavigationStack(path: $path) {
            content()
                .navigationDestination(for: NavigationDestination.self) { destination in
                    switch destination {
                        case .item(let item, let zoomID):
                            ItemView(item: item, zoomID: zoomID)
                        case .itemID(let itemID):
                            ItemLoadView(itemID)
                            
                        case .itemName(let name, let type):
                            ItemIDLoadView(name: name, type: type)
                            
                        case .podcastEpisodes(let viewModel):
                            PodcastEpisodesView()
                                .environment(viewModel)
                        case .tabValue(let tabValue):
                            tabValue.content
                            
                        case .audiobookRow(let title, let audiobooks):
                            RowGridView(title: title, audiobooks: audiobooks)
                    }
                }
                .onReceive(RFNotification[._navigate].publisher()) {
                    let libraryID: String?
                    
                    if case .audiobookLibrary(let library) = tab {
                        libraryID = library.id
                    } else if case .podcastLibrary(let library) = tab {
                        libraryID = library.id
                    } else {
                        libraryID = nil
                    }
                    
                    guard let libraryID, $0.libraryID == libraryID else {
                        return
                    }
                    
                    path.append(.itemID($0))
                }
        }
        .environment(\.library, tab.library)
        .onReceive(RFNotification[.collectionDeleted].publisher()) { collectionID in
            path.removeAll {
                $0.itemID == collectionID
            }
        }
    }
}

enum NavigationDestination: Hashable {
    case item(Item, UUID?)
    case itemID(ItemIdentifier)
    
    case itemName(String, ItemIdentifier.ItemType)
    
    case podcastEpisodes(PodcastViewModel)
    case tabValue(TabValue)
    
    case audiobookRow(String, [Audiobook])
    
    static func item(_ item: Item) -> Self {
        .item(item, nil)
    }
    
    var itemID: ItemIdentifier? {
        switch self {
            case .item(let item, _):
                item.id
            case .itemID(let itemID):
                itemID
            case .podcastEpisodes(let viewModel):
                viewModel.podcast.id
            default:
                nil
        }
    }
}
