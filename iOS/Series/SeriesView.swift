//
//  SeriesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import Defaults
import SPBase

struct SeriesView: View {
    @Environment(\.libraryId) var libraryId
    
    @Default(.audiobooksDisplay) var audiobookDisplay
    @Default(.audiobooksFilter) var audiobooksFilter
    
    @State var audiobooksSortOrder = AudiobookSortFilter.SortOrder.series
    @State var audiobooksAscending = true
    
    let series: Series
    
    @State private var audiobooks = [Audiobook]()
    
    private var visibleAudiobooks: [Audiobook] {
        AudiobookSortFilter.filterSort(audiobooks: audiobooks, filter: audiobooksFilter, order: audiobooksSortOrder, ascending: audiobooksAscending)
    }
    
    var body: some View {
        Group {
            switch audiobookDisplay {
                case .grid:
                    ScrollView {
                        Header(series: series)
                        AudiobookVGrid(audiobooks: visibleAudiobooks)
                            .padding(.horizontal)
                    }
                case .list:
                    List {
                        Header(series: series)
                        AudiobookList(audiobooks: visibleAudiobooks)
                    }
                    .listStyle(.plain)
            }
        }
        .navigationTitle(series.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AudiobookSortFilter(display: $audiobookDisplay, filter: $audiobooksFilter, sort: $audiobooksSortOrder, ascending: $audiobooksAscending)
            }
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .task{ await fetchAudiobooks() }
        .refreshable{ await fetchAudiobooks() }
    }
}

// MARK: Helper

extension SeriesView {
    func fetchAudiobooks() async {
        if let audiobooks = try? await AudiobookshelfClient.shared.getAudiobooks(seriesId: series.id, libraryId: libraryId) {
            self.audiobooks = audiobooks
        }
    }
}

#Preview {
    NavigationStack {
        SeriesView(series: Series.fixture)
    }
}
