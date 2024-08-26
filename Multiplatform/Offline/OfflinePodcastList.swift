//
//  OfflinePodcastList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPFoundation
import SPOffline
import SPOfflineExtended

struct OfflinePodcastList: View {
    let podcasts: [Podcast: [Episode]]
    
    var body: some View {
        ForEach(Array(podcasts.keys).sorted()) { podcast in
            let episodes = podcasts[podcast]!
            
            NavigationLink(destination: OfflinePodcastView(podcast: podcast, episodes: episodes)) {
                PodcastRow(podcast: podcast, episodes: episodes)
            }
        }
        .onDelete { indexSet in
            indexSet.forEach { index in
                OfflineManager.shared.remove(podcastId: Array(podcasts.keys)[index].id)
            }
        }
    }
}

extension OfflinePodcastList {
    struct PodcastRow: View {
        let podcast: Podcast
        let episodes: [Episode]
        
        var body: some View {
            HStack {
                ItemImage(image: podcast.cover)
                    .frame(height: 50)
                
                VStack(alignment: .leading) {
                    Text(podcast.name)
                        .lineLimit(1)
                    
                    if let author = podcast.author {
                        Text(author)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                Text(String(podcast.episodeCount))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            OfflinePodcastList(podcasts: [.fixture: [.fixture]])
        }
    }
}
