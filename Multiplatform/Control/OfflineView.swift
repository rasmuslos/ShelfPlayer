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
    private var listenNowButton: some View {
        Button("panel.listenNow", systemImage: "play.diamond.fill") {
            satellite.present(.listenNow)
        }
    }
    @ViewBuilder
    private var goOnlineButton: some View {
        Button("navigation.offline.disable", systemImage: "network") {
            Task {
                await OfflineMode.shared.refreshAvailability()
            }
        }
    }
    @ViewBuilder
    private var preferencesButton: some View {
        Button("preferences", systemImage: "gearshape") {
            satellite.present(.preferences)
        }
    }
    
    var body: some View {
        GeometryReader { geometryProxy in
            NavigationStack {
                List {
                    if !audiobooks.isEmpty {
                        Section {
                            ForEach(audiobooks) { audiobook in
                                Button {
                                    satellite.start(audiobook.id)
                                } label: {
                                    ItemCompactRow(item: audiobook)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
                                .modifier(ItemStatusModifier(item: audiobook, hoverEffect: nil))
                            }
                        }
                    }
                    
                    ForEach(podcastsFlat) { podcast in
                        Section {
                            ForEach(podcasts[podcast] ?? []) { episode in
                                Button {
                                    satellite.start(episode.id)
                                } label: {
                                    ItemCompactRow(item: episode, context: .offlineEpisode)
                                }
                                .buttonStyle(.plain)
                                .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
                                .modifier(ItemStatusModifier(item: episode, hoverEffect: nil))
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
                            .accessibilityElement(children: .combine)
                        }
                    }
                    
                    goOnlineButton
                    preferencesButton
                }
                .navigationTitle("panel.offline")
                .largeTitleDisplayMode()
                .modifier(PlaybackSafeAreaPaddingModifier())
                .toolbar {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        listenNowButton
                        preferencesButton
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
            .modifier(ApplyLegacyCollapsedForeground())
            .modifier(CompactPlaybackModifier())
            .modifier(RegularPlaybackModifier())
            .modifier(RegularPlaybackBarModifier())
            .environment(\.playbackBottomOffset, 16)
        }
    }
    
    private func loadItems() {
        Task {
            var (audiobooks, episodes, podcasts) = try await (
                PersistenceManager.shared.download.audiobooks(),
                PersistenceManager.shared.download.episodes(),
                PersistenceManager.shared.download.podcasts(),
            )
            
            audiobooks = await withTaskGroup {
                for audiobook in audiobooks {
                    $0.addTask {
                        (await PersistenceManager.shared.progress[audiobook.id].progress, audiobook)
                    }
                }
                
                var resolved = [(Percentage, Audiobook)]()
                
                for await result in $0 {
                    resolved.append(result)
                }
                
                return resolved.sorted {
                    $0.0 > $1.0
                }.map {
                    $1
                }
            }
            podcasts.sort { $0.sortName < $1.sortName }
            
            let grouped = Dictionary(grouping: episodes, by: \.podcastID)
            let mapped = Dictionary(uniqueKeysWithValues: podcasts.map {
                ($0, grouped[$0.id] ?? [])
            })
            
            withAnimation {
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
