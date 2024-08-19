//
//  SeriesLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPFoundation

struct SeriesLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let series: Audiobook.ReducedSeries
    
    @State private var failed = false
    @State private var resolved: Series?
    
    var body: some View {
        if let resolved = resolved {
            SeriesView(series: resolved)
                .refreshable {
                    await loadSeries()
                }
        } else if failed {
            SeriesUnavailableView()
        } else {
            LoadingView()
                .task {
                    await loadSeries()
                }
        }
    }
    
    private func loadSeries() async {
        var id = series.id
        
        if id == nil {
            id = try? await AudiobookshelfClient.shared.getSeriesId(name: series.name, libraryId: libraryId)
        }
        
        guard let id else {
            return
        }
        
        guard let series = await AudiobookshelfClient.shared.getSeries(seriesId: id, libraryId: libraryId) else {
            failed = true
            return
        }
        
        self.resolved = series
    }
}
