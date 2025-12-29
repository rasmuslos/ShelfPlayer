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
    
    private(set) var highlighted: PlayableItem? = Episode.placeholder
    
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
            self?.updateHighlighted(provided: audiobooks)
        }
        
        RFNotification[.progressEntityUpdated].subscribe { [weak self] connectionID, primaryID, groupingID, _ in
            guard self?.lazyLoader.items.contains(where: { $0.id.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }) == true else {
                return
            }
            
            self?.updateHighlighted()
        }
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
            updateHighlighted()
        }
    }
    
    private nonisolated func updateHighlighted(provided audiobooks: [Audiobook]? = nil) {
        Task {
            let audiobooks = await lazyLoader.items
            
            for audiobook in audiobooks {
                if await audiobook.isIncluded(in: .notFinished) {
                    await MainActor.withAnimation {
                        highlighted = audiobook
                    }

                    break
                }
            }
            
            if await highlighted == Episode.placeholder {
                await MainActor.withAnimation {
                    highlighted = nil
                }
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
