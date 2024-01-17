//
//  OfflineView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 12.10.23.
//

import SwiftUI
import SPBaseKit
import SPOfflineKit
import SPPlaybackKit

struct OfflineView: View {
    @State var accountSheetPresented = false
    
    @State var audiobooks = [Audiobook]()
    @State var podcasts = [Podcast: [Episode]]()
    
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
                            AudiobookRow(audiobook: $0)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach {
                                OfflineManager.shared.delete(audiobookId: audiobooks[$0].id)
                            }
                        }
                    }
                }
                
                ForEach(podcasts.sorted { $0.key.name < $1.key.name }, id: \.key.id) { podcast in
                    Section(podcast.key.name) {
                        ForEach(podcast.value) {
                            EpisodeRow(episode: $0)
                        }
                        .onDelete { indexSet in
                            indexSet.forEach { index in
                                podcasts[podcast.key]?.remove(at: index)
                                OfflineManager.shared.delete(episodeId: podcast.value[index].id)
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
                    Label("account.manage", systemImage: "server.rack")
                }
            }
            .navigationTitle("title.offline")
            .sheet(isPresented: $accountSheetPresented) {
                AccountSheet()
            }
            .modifier(NowPlayingBarModifier())
            .onAppear {
            }
        }
    }
}

#Preview {
    OfflineView()
}
