//
//  AllEpisodesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

struct PodcastEpisodesView: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    @ScaledMetric private var seasonPickerHeight: CGFloat = 32
    
    private var allLabel: String {
        String(localized: "item.related.podcast.episodes.all")
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
            EpisodeList(episodes: viewModel.visible, context: .podcast, selected: $viewModel.bulkSelected)
        }
        .listStyle(.plain)
        .navigationTitle("item.related.podcast.episodes")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.load(refresh: true)
        }
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
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                if viewModel.performingBulkAction {
                    ProgressView()
                } else if viewModel.bulkSelected == nil {
                    Button("action.select", systemImage: "circle.dashed") {
                        viewModel.bulkSelected = []
                    }
                } else {
                    Menu("action.select", systemImage: "circle.circle") {
                        Button("item.progress.markAsUnfinished", systemImage: "minus.square") {
                            viewModel.performBulkAction(isFinished: false)
                        }
                        Button("item.progress.markAsFinished", systemImage: "checkmark.square") {
                            viewModel.performBulkAction(isFinished: true)
                        }
                        
                        Divider()
                        
                        Button("action.end", systemImage: "circle.badge.checkmark") {
                            viewModel.bulkSelected = nil
                        }
                    }
                }
                
                PodcastView.ToolbarModifier.OptionsMenu()
            }
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .environment(viewModel)
        .onChange(of: viewModel.search) {
            viewModel.updateVisible()
        }
        .onDisappear {
            viewModel.search = ""
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        PodcastEpisodesView()
    }
    .environment(PodcastViewModel(podcast: .fixture, episodes: .init(repeating: .fixture, count: 7)))
    .previewEnvironment()
}
#endif
