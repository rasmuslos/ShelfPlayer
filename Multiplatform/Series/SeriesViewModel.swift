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
    
    private(set) var highlighted: Audiobook? = .placeholder
    
    var library: Library! {
        didSet {
            lazyLoader.library = library
        }
    }
    
    @MainActor
    init(series: Series) {
        self.series = series
        lazyLoader = .audiobooks(filtered: series.id, sortOrder: nil, ascending: nil)
        lazyLoader.didLoadMore = { [weak self] audiobooks in
            Task { @MainActor [weak self] in
                self?.updateHighlighted(provided: audiobooks)
            }
        }
        
        RFNotification[.progressEntityUpdated].subscribe { [weak self] connectionID, primaryID, groupingID, _ in
            guard self?.lazyLoader.items.contains(where: { $0.id.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }) == true else {
                return
            }
            
            Task { @MainActor [weak self] in
                self?.updateHighlighted()
            }
        }
    }
    
    func refresh() {
        Task {
            try? await ShelfPlayer.refreshItem(itemID: series.id)
            lazyLoader.refresh()
            updateHighlighted()
        }
    }
    
    private func updateHighlighted(provided audiobooks: [Audiobook]? = nil) {
        Task {
            let audiobooks = lazyLoader.items
            
            for audiobook in audiobooks {
                if await audiobook.isIncluded(in: .notFinished) {
                    highlighted = audiobook
                    break
                }
            }
            
            if highlighted == .placeholder, lazyLoader.isLoading == false {
                highlighted = nil
            }
        }
    }
}

extension SeriesViewModel {
    @MainActor
    var sections: [AudiobookSection] {
        lazyLoader.items.map { .audiobook(audiobook: $0) }
    }
}
