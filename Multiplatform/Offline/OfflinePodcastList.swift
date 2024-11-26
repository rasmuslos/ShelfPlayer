//
//  OfflinePodcastList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPFoundation
import SPPersistence
import SPPersistenceExtended

internal struct OfflinePodcastList: View {
    let podcasts: [Podcast: [Episode]]
    
    private var keys: [Podcast] {
        Array(podcasts.keys).sorted()
    }
    
    var body: some View {
        ForEach(keys) { podcast in
            let episodes = podcasts[podcast]!
            
            NavigationLink(destination: OfflinePodcastView(podcast: podcast, episodes: episodes)) {
                PodcastRow(podcast: podcast, episodes: episodes)
            }
            .listRowInsets(.init(top: podcast == keys.first ? 12 : 6, leading: 12, bottom: podcast == keys.last ? 12 : 6, trailing: 12))
        }
        .onDelete { indexSet in
            indexSet.forEach { index in
                OfflineManager.shared.remove(podcastId: Array(podcasts.keys)[index].id)
            }
        }
    }
}

internal extension OfflinePodcastList {
    struct PodcastRow: View {
        let podcast: Podcast
        let episodes: [Episode]
        
        var body: some View {
            HStack(spacing: 0) {
                ItemImage(cover: podcast.cover)
                    .frame(height: 60)
                    .padding(.trailing, 12)
                
                VStack(alignment: .leading) {
                    Text(podcast.name)
                        .lineLimit(1)
                    
                    if !podcast.authors.isEmpty {
                        Text(podcast.authors, format: .list(type: .and, width: .short))
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer(minLength: 12)
                
                Text(String(podcast.episodeCount))
                    .foregroundStyle(.secondary)
            }
            .contentShape(.hoverMenuInteraction, .rect)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            OfflinePodcastList(podcasts: [.fixture: [.fixture]])
        }
    }
}
#endif
