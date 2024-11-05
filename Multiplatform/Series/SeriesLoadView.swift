//
//  SeriesLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct SeriesLoadView: View {
    @Environment(\.library) private var library
    
    let series: Audiobook.ReducedSeries
    
    init(seriesName: String) {
        series = .init(id: nil, name: seriesName, sequence: nil)
    }
    init(series: Audiobook.ReducedSeries) {
        self.series = series
    }
    
    @State private var failed = false
    @State private var resolved: Series?
    
    var body: some View {
        if let resolved = resolved {
            SeriesView(resolved)
        } else if failed {
            SeriesUnavailableView()
                .refreshable {
                    await loadSeries()
                }
        } else {
            LoadingView()
                .task {
                    await loadSeries()
                }
                .refreshable {
                    await loadSeries()
                }
        }
    }
    
    private nonisolated func loadSeries() async {
        var id = await series.id
        
        if id == nil {
            id = try? await AudiobookshelfClient.shared.seriesID(name: series.name, libraryID: library.id)
        }
        
        guard let id else {
            return
        }
        
        guard let series = try? await AudiobookshelfClient.shared.series(seriesId: id, libraryID: library.id) else {
            await MainActor.withAnimation {
                failed = true
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.resolved = series
        }
    }
}
