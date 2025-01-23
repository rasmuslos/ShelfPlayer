//
//  ItemLoadView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct ItemLoadView: View {
    let id: ItemIdentifier
    
    init(_ id: ItemIdentifier) {
        self.id = id
    }
    
    @State private var item: Item? = nil
    @State private var failed = false
    
    var body: some View {
        if let item {
            if let audiobook = item as? Audiobook {
                AudiobookView(audiobook)
            } else if let series = item as? Series {
                SeriesView(series)
            } else if let author = item as? Author {
                AuthorView(author)
            } else if let podcast = item as? Podcast {
                PodcastView(podcast, zoom: false)
            } else if let episode = item as? Episode {
                EpisodeView(episode, zoomID: nil)
            } else {
                ErrorView()
            }
        } else {
            if failed {
                ErrorView()
            } else {
                LoadingView()
            }
        }
    }
    
    private nonisolated func load() {
        Task {
            await MainActor.withAnimation {
                failed = false
            }
            
            let item: Item
            
            do {
                switch id.type {
                case .audiobook, .episode:
                    (item, _, _, _) = try await ABSClient[id.connectionID].playableItem(itemID: id)
                case .author:
                    item = try await ABSClient[id.connectionID].author(with: id)
                case .series:
                    item = try await ABSClient[id.connectionID].series(with: id)
                case .podcast:
                    (item, _) = try await ABSClient[id.connectionID].podcast(with: id)
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

#Preview {
    ItemLoadView(.fixture)
}
