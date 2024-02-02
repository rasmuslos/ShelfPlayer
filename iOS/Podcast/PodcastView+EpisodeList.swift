//
//  AllEpisodesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import SPBase

struct PodcastFullListView: View {
    @Default(.episodesFilter) private var episodesFilter
    
    @Default(.episodesSort) private var episodesSort
    @Default(.episodesAscending) private var episodesAscending
    
    let episodes: [Episode]
    
    @State private var query = ""
    
    private var visibleEpisodes: [Episode] {
        let episodes = EpisodeSortFilter.filterSort(episodes: episodes, filter: episodesFilter, sortOrder: episodesSort, ascending: episodesAscending)
        let query = query.lowercased()
        
        if query == "" {
            return episodes
        }
        
        return episodes.filter { $0.sortName.contains(query) || $0.name.lowercased().contains(query) || ($0.descriptionText?.lowercased() ?? "").contains(query) }
    }
    
    var body: some View {
        List {
            PodcastView.EpisodeList(episodes: visibleEpisodes)
        }
        .listStyle(.plain)
        .navigationTitle("title.episodes")
        .searchable(text: $query)
        .modifier(NowPlayingBarSafeAreaModifier())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EpisodeSortFilter(filter: $episodesFilter, sortOrder: $episodesSort, ascending: $episodesAscending)
            }
        }
    }
}

extension PodcastView {
    struct EpisodeList: View {
        let episodes: [Episode]
        
        var body: some View {
            ForEach(episodes) { episode in
                NavigationLink(destination: EpisodeView(episode: episode)) {
                    EpisodeRow(episode: episode)
                }
                .listRowInsets(.init(top: 5, leading: 15, bottom: 5, trailing: 15))
                .modifier(SwipeActionsModifier(item: episode))
            }
        }
    }
}

extension PodcastFullListView {
    struct EpisodeRow: View {
        let episode: Episode
        
        var body: some View {
            VStack(alignment: .leading) {
                Group {
                    if let formattedReleaseDate = episode.formattedReleaseDate {
                        Text(formattedReleaseDate)
                    } else {
                        Text(verbatim: "")
                    }
                }
                .font(.subheadline.smallCaps())
                .foregroundStyle(.secondary)
                
                Text(episode.name)
                    .font(.headline)
                    .lineLimit(1)
                
                if let description = episode.descriptionText {
                    Text(description)
                        .lineLimit(2)
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }
                
                HStack(alignment: .firstTextBaseline) {
                    EpisodePlayButton(episode: episode)
                        .padding(.bottom, 10)
                    
                    Spacer()
                    DownloadIndicator(item: episode)
                }
            }
            .modifier(EpisodeContextMenuModifier(episode: episode))
        }
    }
}

#Preview {
    NavigationStack {
        PodcastFullListView(episodes: .init(repeating: [.fixture], count: 7))
    }
}
