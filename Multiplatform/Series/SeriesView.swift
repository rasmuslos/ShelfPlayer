//
//  SeriesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import Defaults
import SPBase

internal struct SeriesView: View {
    @Environment(\.libraryId) private var libraryId
    
    @Default(.audiobooksDisplay) private var audiobookDisplay
    @Default(.audiobooksFilter) private var audiobooksFilter
    
    let series: Series
    
    @State private var audiobooksSortOrder = AudiobookSortFilter.SortOrder.series
    @State private var audiobooksAscending = true
    
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
                        Header(series: series, audiobooks: audiobooks)
                        
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
                        Header(series: series, audiobooks: audiobooks)
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        
                        RowTitle(title: String(localized: "books"), fontDesign: .serif)
                            .listRowSeparator(.hidden, edges: .top)
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
        .modifier(NowPlaying.SafeAreaModifier())
        .task {
            await loadAudiobooks()
        }
        .refreshable {
            await loadAudiobooks()
        }
        .userActivity("io.rfk.shelfplayer.series") {
            $0.title = series.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = series.name
            $0.targetContentIdentifier = "series:\(series.name)"
            $0.userInfo = [
                "seriesId": series.id,
                "seriesName": series.name,
            ]
            $0.webpageURL = AudiobookshelfClient.shared.serverUrl.appending(path: "library").appending(path: libraryId).appending(path: "series").appending(path: series.id)
        }
    }
    
    func loadAudiobooks() async {
        guard let audiobooks = try? await AudiobookshelfClient.shared.getAudiobooks(seriesId: series.id, libraryId: libraryId) else {
            return
        }
        
        self.audiobooks = audiobooks
    }
}

#Preview {
    NavigationStack {
        SeriesView(series: Series.fixture)
    }
}
