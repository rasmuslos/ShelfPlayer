//
//  SeriesViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.08.24.
//

import Foundation
import SwiftUI
import Defaults
import DefaultsMacros
import ShelfPlayerKit

@Observable @MainActor
final class SeriesViewModel {
    let series: Series
    
    let lazyLoader: LazyLoadHelper<Audiobook, Void?>
    
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
        lazyLoader = .audiobooks(seriesID: series.id)
    }
    
    var audiobookIDs: [ItemIdentifier] {
        guard !lazyLoader.items.isEmpty else {
            return series.audiobooks.map(\.id)
        }
        
        return lazyLoader.items.map(\.id)
    }
}

extension SeriesViewModel {
    @MainActor
    var sections: [AudiobookSection] {
        lazyLoader.items.map { .audiobook(audiobook: $0) }
    }
}
