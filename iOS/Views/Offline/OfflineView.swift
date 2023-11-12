//
//  OfflineView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import SwiftUI

struct OfflineView: View {
    @State var accountSheetPresented = false
    
    @State var audiobooks = [OfflineAudiobook]()
    @State var podcasts = [OfflinePodcast: [OfflineEpisode]]()
    
    var body: some View {
        NavigationStack {
            List {
                if !audiobooks.isEmpty {
                    Section("downloads.audiobooks") {
                        if audiobooks.isEmpty {
                            Text("downloads.empty")
                                .font(.caption.smallCaps())
                                .foregroundStyle(.secondary)
                        }
                        
                        ForEach(audiobooks) {
                            AudiobookRow(audiobook: Audiobook.convertFromOffline(audiobook: $0))
                        }
                        .onDelete { indexSet in
                            indexSet.forEach {
                                try? OfflineManager.shared.deleteAudiobook(audiobookId: audiobooks[$0].id)
                            }
                        }
                    }
                }
                
                ForEach(podcasts.sorted { $0.key.name < $1.key.name }, id: \.key.id) { podcast in
                    Section(podcast.key.name) {
                        ForEach(podcast.value) {
                            EpisodeRow(episode: Episode.convertFromOffline(episode: $0))
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                podcasts[podcast.key]?.remove(at: index)
                                try? OfflineManager.shared.deleteEpisode(episodeId: podcast.value[index].id)
                            }
                            
                            if podcasts[podcast.key]?.count == 0 {
                                podcasts[podcast.key] = nil
                            }
                        }
                    }
                }
                
                Button {
                    NotificationCenter.default.post(name: Library.libraryChangedNotification, object: nil, userInfo: [
                        "offline": false,
                    ])
                } label: {
                    Label("offline.disable", systemImage: "network")
                }
                Button {
                    accountSheetPresented.toggle()
                } label: {
                    Label("account.manage", systemImage: "bolt.horizontal.circle")
                }
            }
            .navigationTitle("title.offline")
            .sheet(isPresented: $accountSheetPresented) {
                AccountSheet()
            }
            .modifier(NowPlayingBarModifier())
            .onAppear {
                let episodes: [OfflineEpisode]
                (audiobooks, episodes) = (OfflineManager.shared.getAllAudiobooks(), OfflineManager.shared.getAllEpisodes())
                
                episodes.forEach { episode in
                    if podcasts[episode.podcast] == nil {
                        podcasts[episode.podcast] = []
                    }
                    
                    podcasts[episode.podcast]?.append(episode)
                }
                
                podcasts.forEach {
                    podcasts[$0.key]!.sort { $0.index < $1.index }
                }
            }
        }
    }
}

#Preview {
    OfflineView()
}
