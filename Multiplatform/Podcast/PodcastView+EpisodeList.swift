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
    @Environment(PodcastViewModel.self) private var viewModel
    
    @ScaledMetric private var seasonPickerHeight: CGFloat = 32
    
    private var allLabel: String {
        String(localized: "episodes.all")
    }
    private var pickerBinding: Binding<String> {
        .init { viewModel.seasonFilter ?? allLabel } set: {
            if $0 == allLabel {
                viewModel.seasonFilter = nil
            } else {
                viewModel.seasonFilter = $0
            }
        }
    }
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        List {
            EpisodeList(episodes: viewModel.visible, context: .podcast)
        }
        .listStyle(.plain)
        .navigationTitle("episodes")
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .top) {
            if !viewModel.seasons.isEmpty {
                ZStack(alignment: .top) {
                    Rectangle()
                        .fill(.bar)
                        .ignoresSafeArea(edges: .top)
                        .frame(height: seasonPickerHeight + 8)
                    
                    SlidingSeasonPicker(selection: pickerBinding, values: viewModel.seasons + [allLabel], makeLabel: viewModel.seasonLabel)
                }
            }
        }
        .searchable(text: $viewModel.search, placement: .toolbar)
        // .modifier(NowPlaying.SafeAreaModifier())
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                PodcastView.ToolbarModifier.OptionsMenu()
            }
        }
        .environment(viewModel)
        .onDisappear {
            viewModel.search = ""
        }
    }
}

#Preview {
    NavigationStack {
        PodcastEpisodesView()
    }
    .environment(PodcastViewModel(podcast: .fixture, episodes: .init(repeating: .fixture, count: 7)))
    .previewEnvironment()
}
