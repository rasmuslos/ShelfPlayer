//
//  OfflineView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 05.04.25.
//

import SwiftUI
import ShelfPlayback

struct OfflineView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(Satellite.self) private var satellite
    @Environment(OfflineMode.self) private var offlineMode

    init() {
        let appearance = UINavigationBarAppearance()

        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance

        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().compactAppearance = appearance
    }

    @State private var audiobooks = [Audiobook]()
    @State private var podcasts = [Podcast: [Episode]]()
    @State private var availableWidth: CGFloat = 0

    private let targetContentWidth: CGFloat = 720

    private var horizontalRowInset: CGFloat {
        guard horizontalSizeClass == .regular, availableWidth > targetContentWidth else { return 12 }
        return max(12, (availableWidth - targetContentWidth) / 2)
    }

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
        if offlineMode.isLoading {
            ProgressView()
                .accessibilityLabel(Text("navigation.offline.disable"))
        } else {
            Button("navigation.offline.disable", systemImage: "network") {
                Task {
                    await offlineMode.refreshAvailability()
                }
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
                                .listRowInsets(.init(top: 12, leading: horizontalRowInset, bottom: 12, trailing: horizontalRowInset))
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
                                .listRowInsets(.init(top: 12, leading: horizontalRowInset, bottom: 12, trailing: horizontalRowInset))
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
                            .padding(.horizontal, max(0, horizontalRowInset - 20))
                        }
                    }

                    goOnlineButton
                    preferencesButton
                }
                .background {
                    GeometryReader { proxy in
                        Color.clear
                            .onChange(of: proxy.size.width, initial: true) {
                                availableWidth = proxy.size.width
                            }
                    }
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
            .onReceive(PersistenceManager.shared.download.events.statusChanged) { _ in
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

            var mapped = [Podcast: [Episode]]()
            for podcast in podcasts {
                mapped[podcast] = await Podcast.filterSort(grouped[podcast.id] ?? [], podcastID: podcast.id)
            }

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
