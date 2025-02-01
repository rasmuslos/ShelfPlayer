//
//  ItemLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemLoadView: View {
    @Environment(\.namespace) private var namespace
    
    let id: ItemIdentifier
    let zoom: Bool
    
    init(_ id: ItemIdentifier, zoom: Bool = false) {
        self.id = id
        self.zoom = zoom
    }
    
    @State private var item: Item? = nil
    @State private var contained = [Item]()
    
    @State private var failed = false
    
    var body: some View {
        Group {
            if let item {
                if let audiobook = item as? Audiobook {
                    AudiobookView(audiobook)
                } else if let series = item as? Series {
                    SeriesView(series)
                } else if let author = item as? Author {
                    AuthorView(author)
                } else if let podcast = item as? Podcast, let episodes = contained as? [Episode] {
                    PodcastView(podcast, episodes: episodes, zoom: false)
                } else if let episode = item as? Episode {
                    EpisodeView(episode, zoomID: nil)
                } else {
                    ErrorView()
                }
            } else {
                if failed {
                    ErrorView(itemID: id)
                        .refreshable {
                            load()
                        }
                } else {
                    LoadingView()
                        .task {
                            load()
                        }
                        .refreshable {
                            load()
                        }
                }
            }
        }
        .modify {
            if zoom {
                $0
                    .navigationTransition(.zoom(sourceID: "item_\(id)", in: namespace!))
            } else {
                $0
            }
        }
    }
    
    private nonisolated func load() {
        Task {
            await MainActor.withAnimation {
                failed = false
            }
            
            let item: Item
            var contained = [Item]()
            
            do {
                switch id.type {
                case .audiobook, .episode:
                    (item, _, _, _) = try await ABSClient[id.connectionID].playableItem(itemID: id)
                case .author:
                    item = try await ABSClient[id.connectionID].author(with: id)
                case .series:
                    item = try await ABSClient[id.connectionID].series(with: id)
                case .podcast:
                    (item, contained) = try await ABSClient[id.connectionID].podcast(with: id)
                }
                
                await MainActor.withAnimation {
                    self.item = item
                    self.contained = contained
                }
            } catch {
                await MainActor.withAnimation {
                    failed = false
                }
                
                return
            }
            
            await MainActor.withAnimation {
                self.item = item
            }
        }
    }
}

#if DEBUG
#Preview {
    ItemLoadView(.fixture)
}
#endif
