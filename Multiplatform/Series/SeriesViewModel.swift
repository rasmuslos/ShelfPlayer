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
internal class SeriesViewModel {
    @MainActor internal let series: Series
    
    @MainActor private(set) var lazyLoader: LazyLoadHelper<Audiobook, AudiobookSortOrder>
    
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
    @MainActor internal var sortOrder: AudiobookSortOrder
    
    @MainActor
    init(series: Series) {
        self.series = series
        
        lazyLoader = .audiobooks(seriesID: series.id)
        
        filter = Defaults[.audiobooksFilter]
        displayMode = Defaults[.audiobooksDisplay]
        
        ascending = true
        sortOrder = .series
    }
}

internal extension SeriesViewModel {
    @MainActor
    var visible: [Audiobook] {
        let filtered = AudiobookSortFilter.filterSort(audiobooks: lazyLoader.items, filter: filter, order: sortOrder, ascending: ascending)
        
        if filtered.isEmpty {
            return AudiobookSortFilter.sort(audiobooks: lazyLoader.items, order: sortOrder, ascending: ascending)
        }
        
        return filtered
    }
    
    @MainActor
    var images: [Cover?] {
        if visible.isEmpty {
            return series.covers
        }
        
        return visible.map { $0.cover }
    }
    
    @MainActor
    var headerImageCount: Int {
        min(images.count, 5)
    }
}
