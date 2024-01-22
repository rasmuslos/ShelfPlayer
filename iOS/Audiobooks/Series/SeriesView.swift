//
//  SeriesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPBase

struct SeriesView: View {
    @Environment(\.libraryId) var libraryId
    
    let series: Series
    
    @State var audiobooks = [Audiobook]()
    @State var displayOrder = AudiobooksFilterSort.getDisplayType()
    @State var filter = AudiobooksFilterSort.getFilter()
    @State var sortOrder = AudiobooksFilterSort.getSortOrder()
    @State var ascending = AudiobooksFilterSort.getAscending()
    
    var body: some View {
        Group {
            let sorted = AudiobooksFilterSort.filterSort(audiobooks: audiobooks, filter: filter, order: sortOrder, ascending: ascending)
            
            if displayOrder == .grid {
                ScrollView {
                    Header(series: series)
                    AudiobookGrid(audiobooks: sorted)
                        .padding(.horizontal)
                }
            } else if displayOrder == .list {
                List {
                    Header(series: series)
                    AudiobooksList(audiobooks: sorted)
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle(series.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AudiobooksFilterSort(display: $displayOrder, filter: $filter, sort: $sortOrder, ascending: $ascending)
            }
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .task(fetchAudiobooks)
        .refreshable(action: fetchAudiobooks)
    }
}

// MARK: Helper

extension SeriesView {
    @Sendable
    func fetchAudiobooks() {
        Task.detached {
            audiobooks = (try? await AudiobookshelfClient.shared.getAudiobooks(seriesId: series.id, libraryId: libraryId)) ?? []
        }
    }
}

#Preview {
    NavigationStack {
        SeriesView(series: Series.fixture)
    }
}
