//
//  SeriesViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.08.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

@Observable
internal final class SeriesViewModel {
    @MainActor internal let series: Series
    @MainActor private(set) internal var filteredSeriesIDs: [String]
    
    @MainActor private(set) var lazyLoader: LazyLoadHelper<Audiobook, Void?>
    
    @MainActor internal var library: Library! {
        didSet {
            lazyLoader.library = library
        }
    }
    
    @MainActor internal var filter: ItemFilter {
        didSet {
            Defaults[.audiobooksFilter] = filter
        }
    }
    @MainActor internal var displayMode: ItemDisplayType {
        didSet {
            Defaults[.audiobooksDisplay] = displayMode
        }
    }
    
    @MainActor internal var ascending: Bool
    
    @MainActor
    init(series: Series, filteredSeriesIDs: [String]) {
        self.series = series
        self.filteredSeriesIDs = filteredSeriesIDs
        
        lazyLoader = .audiobooks(seriesID: series.id.primaryID)
        
        filter = Defaults[.audiobooksFilter]
        displayMode = Defaults[.audiobooksDisplay]
        
        ascending = true
    }
}

internal extension SeriesViewModel {
    @MainActor
    var visible: [AudiobookSection] {
        /*
        var audiobooks = Audiobook.filterSort(lazyLoader.items, filter: filter, sortOrder: sortOrder, ascending: ascending)
        
        if audiobooks.isEmpty {
            audiobooks = Audiobook.sort(lazyLoader.items, sortOrder: sortOrder, ascending: ascending)
        }
        
        if !filteredSeriesIDs.isEmpty {
            // audiobooks = audiobooks.filter { filteredSeriesIDs.contains($0.id) }
        }
         */
        
        // return audiobooks.map { .audiobook(audiobook: $0) }
        return lazyLoader.items.map { .audiobook(audiobook: $0) }
    }
    
    @MainActor
    var images: [Cover?] {
        if visible.isEmpty {
            return series.covers
        }
        
        return visible.compactMap {
            if case .audiobook(let audiobook) = $0 {
                return audiobook.cover
            }
            
            return nil
        }
    }
    
    @MainActor
    var headerImageCount: Int {
        min(images.count, 5)
    }
    
    func resetFilter() {
        Task { @MainActor in
            withAnimation(.smooth) {
                // filteredSeriesIDs = []
            }
        }
    }
}
