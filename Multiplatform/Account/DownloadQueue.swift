//
//  DownloadQueue.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 03.10.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

internal struct DownloadQueue: View {
    @State private var audiobooks: [Audiobook] = []
    @State private var podcasts: [Podcast: [Episode]] = [:]
    
    @State private var errorNotify = false
    
    private var podcastsKeys: [Podcast] {
        Array(podcasts.keys).sorted()
    }
    
    var body: some View {
        Section {
            if audiobooks.isEmpty && podcasts.isEmpty {
                Text("downloadQueue.empty")
                    .foregroundStyle(.secondary)
            }
            
            Section {
                ForEach(audiobooks) {
                    DownloadAudiobookRow(audiobook: $0)
                        .listRowInsets(.init(top: $0 == audiobooks.first ? 12 : 6, leading: 12, bottom: $0 == audiobooks.last ? 12 : 6, trailing: 20))
                }
                .onDelete {
                    for index in $0 {
                        // OfflineManager.shared.remove(audiobookId: audiobooks[index].id)
                    }
                }
            }
            
            Section {
                ForEach(podcastsKeys) { podcast in
                    let episodes = podcasts[podcast]!
                    
                    HStack(spacing: 12) {
                        ItemImage(cover: podcast.cover)
                            .frame(width: 60)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            Text(podcast.name)
                                .lineLimit(1)
                            Text("\(episodes.count) episodes")
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listRowInsets(.init(top: podcast == podcastsKeys.first ? 12 : 6, leading: 12, bottom: 6, trailing: 20))
                    
                    ForEach(episodes) { episode in
                        DownloadEpisodeRow(episode: episode)
                            .listRowInsets(.init(top: 6, leading: 12, bottom: 6, trailing: 20))
                    }
                    .onDelete {
                        for index in $0 {
                            // OfflineManager.shared.remove(episodeId: episodes[index].id, allowPodcastDeletion: true)
                        }
                    }
                }
            }
        } header: {
            Text("downloadQueue")
        }
        .sensoryFeedback(.error, trigger: errorNotify)
        .onAppear {
            fetchItems()
        }
        /*
        .onReceive(NotificationCenter.default.publisher(for: OfflineManager.downloadProgressUpdatedNotification)) { _ in
            fetchItems()
        }
         */
    }
    
    private func fetchItems() {
        do {
            /*
            podcasts = try OfflineManager.shared.downloading()
            audiobooks = try OfflineManager.shared.downloading()
             */
        } catch {
            errorNotify.toggle()
        }
    }
}

private struct DownloadAudiobookRow: View {
    let audiobook: Audiobook
    
    var body: some View {
        HStack(spacing: 12) {
            ItemImage(cover: audiobook.cover)
                .frame(width: 60)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(audiobook.name)
                    .lineLimit(1)
                
                if !audiobook.authors.isEmpty {
                    Text(audiobook.authors, format: .list(type: .and, width: .short))
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer()
            
            // DownloadProgressIndicator(itemId: audiobook.id, small: false)
        }
    }
}
private struct DownloadEpisodeRow: View {
    let episode: Episode
    
    var body: some View {
        HStack(spacing: 0) {
            Text(episode.name)
                .lineLimit(1)
            
            Spacer(minLength: 12)
            
            // DownloadProgressIndicator(itemId: episode.id, small: false)
        }
    }
}

#Preview {
    List {
        DownloadQueue()
    }
}
