//
//  OfflineView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 05.04.25.
//

import SwiftUI
import ShelfPlayback

struct OfflineView: View {
    @Environment(Satellite.self) private var satellite
    
    @State private var audiobooks = [Audiobook]()
    @State private var podcasts = [Podcast: [Episode]]()
    
    private var podcastsFlat: [Podcast] {
        Array(podcasts.keys.sorted())
    }
    
    @ViewBuilder
    private var goOnlineButton: some View {
        Button("navigation.offline.disable", systemImage: "network") {
            RFNotification[.changeOfflineMode].send(payload: false)
        }
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            NavigationStack {
                List {
                    if !audiobooks.isEmpty {
                        Section("row.downloaded.audiobooks") {
                            ForEach(audiobooks) { audiobook in
                                ItemCompactRow(item: audiobook) {
                                    satellite.start(audiobook.id)
                                }
                            }
                        }
                    }
                    
                    ForEach(podcastsFlat) { podcast in
                        Section {
                            ForEach(podcasts[podcast] ?? []) { episode in
                                ItemCompactRow(item: episode, hideImage: true) {
                                    satellite.start(episode.id)
                                }
                            }
                        } header: {
                            HStack(spacing: 0) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(podcast.authors, format: .list(type: .and, width: .short))
                                        .font(.caption)
                                        .lineLimit(1)
                                    
                                    Text(podcast.name)
                                        .bold()
                                        .lineLimit(2)
                                }
                                
                                Spacer(minLength: 8)
                                
                                ItemImage(item: podcast, size: .small)
                                    .frame(width: 44)
                            }
                        }
                    }
                    
                    goOnlineButton
                }
                .navigationTitle("panel.offline")
                .modifier(CompactPreferencesToolbarModifier())
                .modifier(PlaybackSafeAreaPaddingModifier())
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        goOnlineButton
                    }
                }
            }
            .onAppear {
                loadItems()
            }
            .refreshable {
                loadItems()
            }
            .onReceive(RFNotification[.downloadStatusChanged].publisher()) { _ in
                loadItems()
            }
            .modifier(CompactPlaybackModifier(ready: true))
            .environment(\.playbackBottomOffset, 16)
        }
    }
    
    private nonisolated func loadItems() {
        Task {
            let (audiobooks, episodes, podcasts) = try await (
                PersistenceManager.shared.download.audiobooks(),
                PersistenceManager.shared.download.episodes(),
                PersistenceManager.shared.download.podcasts(),
            )
            
            let grouped = Dictionary(grouping: episodes, by: \.podcastID)
            let mapped = Dictionary(uniqueKeysWithValues: podcasts.map {
                ($0, grouped[$0.id] ?? [])
            })
            
            await MainActor.withAnimation {
                self.audiobooks = audiobooks
                self.podcasts = mapped
            }
        }
    }
}

#if DEBUG
#Preview {
    OfflineView()
        .previewEnvironment()
}
#endif
