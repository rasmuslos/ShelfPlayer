//
//  SeriesViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.08.24.
//

import Foundation
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class SeriesViewModel {
    let series: Series
    
    let lazyLoader: LazyLoadHelper<Audiobook, AudiobookSortOrder?>
    
    @ObservableDefault(.audiobooksFilter) @ObservationIgnored
    var filter: ItemFilter
    @ObservableDefault(.audiobooksRestrictToPersisted) @ObservationIgnored
    var restrictToPersisted: Bool
    @ObservableDefault(.audiobooksDisplayType) @ObservationIgnored
    var displayType: ItemDisplayType
    
    var library: Library! {
        didSet {
            lazyLoader.library = library
        }
    }
    
    @MainActor
    init(series: Series) {
        self.series = series
        lazyLoader = .audiobooks(filtered: series.id, sortOrder: nil, ascending: nil)
    }
    
    var audiobookIDs: [ItemIdentifier] {
        guard !lazyLoader.items.isEmpty else {
            return series.audiobooks.map(\.id)
        }
        
        return lazyLoader.items.map(\.id)
    }
    
    nonisolated func refresh() {
        Task {
            try? await ShelfPlayer.refreshItem(itemID: series.id)
            lazyLoader.refresh()
        }
    }
}

extension SeriesViewModel {
    @MainActor
    var sections: [AudiobookSection] {
        lazyLoader.items.map { .audiobook(audiobook: $0) }
    }
}
