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
    @MainActor private(set) var audiobooks: [Audiobook]
    
    @MainActor internal var libraryID: String!
    
    @MainActor internal var filter: AudiobookSortFilter.Filter
    @MainActor internal var displayMode: AudiobookSortFilter.DisplayType
    
    @MainActor internal var ascending: Bool
    @MainActor internal var sortOrder: AudiobookSortFilter.SortOrder
    
    @MainActor
    init(series: Series) {
        self.series = series
        
        audiobooks = []
        
        filter = Defaults[.audiobooksFilter]
        displayMode = Defaults[.audiobooksDisplay]
        
        ascending = Defaults[.audiobooksAscending]
        sortOrder = Defaults[.audiobooksSortOrder]
    }
}

internal extension SeriesViewModel {
    func load() async {
        guard let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(seriesId: series.id, libraryId: libraryID) else {
            return
        }
        
        await MainActor.withAnimation {
            self.audiobooks = audiobooks
        }
    }
}

internal extension SeriesViewModel {
    @MainActor
    var visible: [Audiobook] {
        let filtered = AudiobookSortFilter.filterSort(audiobooks: audiobooks, filter: filter, order: sortOrder, ascending: ascending)
        
        if filtered.isEmpty {
            return AudiobookSortFilter.sort(audiobooks: audiobooks, order: sortOrder, ascending: ascending)
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
