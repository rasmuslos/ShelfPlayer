//
//  SeriesLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPBase

struct SeriesLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let series: Audiobook.ReducedSeries
    
    @State private var failed = false
    @State private var resolved: Series?
    
    var body: some View {
        Group {
            if failed {
                SeriesUnavailableView()
            } else if let resolved = resolved {
                SeriesView(series: resolved)
            } else {
                LoadingView()
                    .task { await fetchSeries() }
            }
        }
        .refreshable { await fetchSeries() }
    }
}

extension SeriesLoadView {
    func fetchSeries() async {
        var id = series.id
        
        if id == nil {
            id = await AudiobookshelfClient.shared.getSeriesId(name: series.name, libraryId: libraryId)
        }
        
        if let id = id, let series = await AudiobookshelfClient.shared.getSeries(seriesId: id, libraryId: libraryId) {
            self.resolved = series
        } else {
            failed = true
        }
    }
}
