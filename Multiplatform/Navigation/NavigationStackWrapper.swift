//
//  NavigationSTackWrapper.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 11.01.25.
//

import SwiftUI
import ShelfPlayback

struct NavigationStackWrapper<Content: View>: View {
    @Environment(TabRouterViewModel.self) private var tabRouterViewModel
    
    let tab: TabValue
    var content: () -> Content
    
    @State private var context: NavigationContext
    
    init(tab: TabValue, @ViewBuilder content: @escaping () -> Content) {
        self.tab = tab
        self.content = content
        
        context = .init(tab: tab)
    }
    
    var body: some View {
        NavigationStack(path: $context.path) {
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
                            TabRouter.panel(for: tabValue)
                            
                        case .audiobookRow(let title, let audiobooks):
                            RowGridView(title: title, audiobooks: audiobooks)
                    }
                }
                .onReceive(RFNotification[._navigate].publisher()) {
                    guard tab.libraryID == .convertItemIdentifierToLibraryIdentifier($0), tabRouterViewModel.tabValue == tab else {
                        return
                    }
                    
                    context.path.append(.itemID($0))
                }
        }
        .environment(\.navigationContext, context)
        .onReceive(RFNotification[.collectionDeleted].publisher()) { collectionID in
            context.path.removeAll {
                $0.itemID == collectionID
            }
        }
    }
}

@MainActor @Observable
final class NavigationContext {
    let tab: TabValue
    
    init(tab: TabValue) {
        self.tab = tab
    }
    
    var path = [NavigationDestination]()
}
extension EnvironmentValues {
    @Entry var navigationContext: NavigationContext? = nil
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
    var label: String {
        switch self {
            case .item(let item, _):
                item.name
            case .itemID(let itemID):
                itemID.type.label
            case .itemName(let name, _):
                name
            case .podcastEpisodes(let viewModel):
                "\(String(localized: "item.related.podcast.episodes")): \(viewModel.podcast.name)"
            case .tabValue(let tab):
                tab.label
            case .audiobookRow(let title, _):
                title
        }
    }
}
