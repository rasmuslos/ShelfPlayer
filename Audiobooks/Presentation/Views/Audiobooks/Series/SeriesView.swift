//
//  SeriesView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI

struct SeriesView: View {
    @Environment(\.libraryId) var libraryId
    
    let series: Series
    
    @State var audiobooks = [Audiobook]()
    @State var displayOrder = AudiobooksSort.getDisplayType()
    @State var sortOrder = AudiobooksSort.getSortOrder()
    
    var body: some View {
        Group {
            let sorted = AudiobooksSort.sort(audiobooks: audiobooks, order: sortOrder)
            
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
                AudiobooksSort(display: $displayOrder, sort: $sortOrder)
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
            audiobooks = (try? await AudiobookshelfClient.shared.getAudiobooksInSeries(seriesId: series.id, libraryId: libraryId)) ?? []
        }
    }
}

#Preview {
    NavigationStack {
        SeriesView(series: Series.fixture)
    }
}
