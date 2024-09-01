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

internal struct OfflinePodcastList: View {
    let podcasts: [Podcast: [Episode]]
    
    var body: some View {
        ForEach(Array(podcasts.keys).sorted()) { podcast in
            let episodes = podcasts[podcast]!
            
            NavigationLink(destination: OfflinePodcastView(podcast: podcast, episodes: episodes)) {
                PodcastRow(podcast: podcast, episodes: episodes)
            }
            .listRowInsets(.init(top: 6, leading: 12, bottom: 6, trailing: 12))
            .padding(.top, podcast == podcasts.keys.first ? 6 : 0)
            .padding(.bottom, podcast == podcasts.keys.reversed().first ? 6 : 0)
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
                    
                    if let author = podcast.author {
                        Text(author)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer(minLength: 12)
                
                Text(String(podcast.episodeCount))
                    .foregroundStyle(.secondary)
            }
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
