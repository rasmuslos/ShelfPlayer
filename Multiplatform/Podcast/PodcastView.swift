//
//  PodcastView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

struct PodcastView: View {
    @Environment(\.library) private var library
    @Environment(\.namespace) private var namespace
    
    let zoom: Bool
    
    @State private var viewModel: PodcastViewModel
    
    init(_ podcast: Podcast, episodes: [Episode] = [], zoom: Bool) {
        self.zoom = zoom
        _viewModel = .init(initialValue: .init(podcast: podcast, episodes: episodes))
    }
    
    var body: some View {
        List {
            Header()
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
            
            if viewModel.episodes.isEmpty {
                ProgressView()
            } else if viewModel.visible.isEmpty {
                EmptyCollectionView.Inner()
                    .listRowSeparator(.hidden)
                    .listRowInsets(.init(top: 40, leading: 20, bottom: 20, trailing: 20))
            } else {
                HStack {
                    Menu {
                        ForEach(viewModel.seasons, id: \.hashValue) { season in
                            Toggle(viewModel.seasonLabel(of: season), isOn: .init { viewModel.seasonFilter == season } set: {
                                if $0 {
                                    viewModel.seasonFilter = season
                                } else {
                                    viewModel.seasonFilter = nil
                                }
                            })
                        }
                    } label: {
                        HStack(spacing: 8) {
                            Group {
                                if let season = viewModel.seasonFilter {
                                    Text(viewModel.seasonLabel(of: season))
                                } else {
                                    Text("item.related.podcast.episodes")
                                }
                            }
                            .bold()
                            
                            if !viewModel.seasons.isEmpty {
                                Image(systemName: "chevron.up.chevron.down")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    
                    NavigationLink(value: NavigationDestination.podcastEpisodes(viewModel)) {
                        HStack(spacing: 0) {
                            Spacer(minLength: 0)
                            
                            Text("item.related.podcast.episodes.all")
                        }
                    }
                }
                .padding(.horizontal, 20)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .alignmentGuide(.listRowSeparatorLeading) { _ in 20 }
                
                EpisodeList(episodes: viewModel.visible, context: .podcast, selected: .constant(nil))
            }
        }
        .listStyle(.plain)
        .ignoresSafeArea(edges: .top)
        .modify(if: zoom) {
            $0
                .navigationTransition(.zoom(sourceID: "item_\(viewModel.podcast.id)", in: namespace!))
        }
        .modifier(ToolbarModifier())
        .modifier(PlaybackSafeAreaPaddingModifier())
        .environment(viewModel)
        .task {
            viewModel.load(refresh: false)
        }
        .refreshable {
            viewModel.load(refresh: true)
        }
        .userActivity("io.rfk.shelfPlayer.item") { activity in
            activity.title = viewModel.podcast.name
            activity.isEligibleForHandoff = true
            activity.isEligibleForPrediction = true
            activity.persistentIdentifier = viewModel.podcast.id.description
            
            Task {
                try await activity.webpageURL = viewModel.podcast.id.url
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PodcastView(Podcast.fixture, episodes: .init(repeating: .fixture, count: 7), zoom: true)
    }
    .previewEnvironment()
}
#endif
