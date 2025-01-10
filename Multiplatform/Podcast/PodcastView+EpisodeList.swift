//
//  AllEpisodesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PodcastEpisodesView: View {
    @Binding var viewModel: PodcastViewModel
    
    var body: some View {
        List {
            EpisodeSingleList(episodes: viewModel.filtered)
        }
        .listStyle(.plain)
        .navigationTitle("episodes")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $viewModel.search, placement: .toolbar)
        // .modifier(NowPlaying.SafeAreaModifier())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                EpisodeSortFilter(filter: $viewModel.filter, sortOrder: $viewModel.sortOrder, ascending: $viewModel.ascending)
            }
        }
    }
}

#if DEBUG
#Preview {
    @Previewable @State var viewModel: PodcastViewModel = .init(podcast: .fixture, episodes: .init(repeating: [.fixture], count: 7))
    
    NavigationStack {
        PodcastEpisodesView(viewModel: $viewModel)
    }
}
#endif
