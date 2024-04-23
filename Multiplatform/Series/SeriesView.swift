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
    @Environment(\.libraryId) private var libraryId
    
    @Default(.audiobooksDisplay) private var audiobookDisplay
    @Default(.audiobooksFilter) private var audiobooksFilter
    
    @State private var audiobooksSortOrder = AudiobookSortFilter.SortOrder.series
    @State private var audiobooksAscending = true
    
    let series: Series
    
    @State private var audiobooks = [Audiobook]()
    
    private var visibleAudiobooks: [Audiobook] {
        let filtered = AudiobookSortFilter.filterSort(audiobooks: audiobooks, filter: audiobooksFilter, order: audiobooksSortOrder, ascending: audiobooksAscending)
        
        if filtered.isEmpty {
            return AudiobookSortFilter.sort(audiobooks: audiobooks, order: audiobooksSortOrder, ascending: audiobooksAscending)
        }
        
        return filtered
    }
    
    var body: some View {
        Group {
            switch audiobookDisplay {
                case .grid:
                    ScrollView {
                        Header(series: series)
                        
                        HStack {
                            RowTitle(title: String(localized: "books"), fontDesign: .serif)
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        AudiobookVGrid(audiobooks: visibleAudiobooks)
                            .padding(.horizontal, 20)
                    }
                case .list:
                    List {
                        Header(series: series)
                        RowTitle(title: String(localized: "books"), fontDesign: .serif)
                            .listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 20))
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
