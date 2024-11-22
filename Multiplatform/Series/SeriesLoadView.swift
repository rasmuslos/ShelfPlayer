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
    
    let seriesID: String?
    let seriesName: String?
    
    let filteredIDs: [String]
    
    init(seriesID: String, filteredIDs: [String] = []) {
        self.seriesID = seriesID
        seriesName = nil
        
        self.filteredIDs = filteredIDs
    }
    init(seriesName: String, filteredIDs: [String] = []) {
        seriesID = nil
        self.seriesName = seriesName
        
        self.filteredIDs = filteredIDs
    }
    init(series: Audiobook.ReducedSeries, filteredIDs: [String] = []) {
        seriesID = series.id
        seriesName = series.name
        
        self.filteredIDs = filteredIDs
    }
    
    @State private var failed = false
    @State private var resolved: Series?
    
    var body: some View {
        if let resolved = resolved {
            SeriesView(resolved, filteredIDs: filteredIDs)
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
        do {
            let seriesID: String
            
            if let id = self.seriesID {
                seriesID = id
            } else if let seriesName {
                let id = try await AudiobookshelfClient.shared.seriesID(name: seriesName, libraryID: library.id)
                seriesID = id
            } else {
                throw GenericError.missing
            }
            
            let series = try await AudiobookshelfClient.shared.series(seriesId: seriesID, libraryID: library.id)
            
            await MainActor.withAnimation {
                self.resolved = series
            }
        } catch {
            await MainActor.withAnimation {
                failed = true
            }
        }
    }
}
