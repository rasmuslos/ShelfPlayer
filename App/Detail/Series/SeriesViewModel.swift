//
//  SeriesViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.08.24.
//

import Foundation
import Combine
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class SeriesViewModel {
    private var observerSubscriptions = Set<AnyCancellable>()

    let series: Series

    let lazyLoader: LazyLoadHelper<Audiobook, AudiobookSortOrder?>

    var filter: ItemFilter
    var restrictToPersisted: Bool
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

        let settings = AppSettings.shared
        filter = settings.audiobooksFilter
        restrictToPersisted = settings.audiobooksRestrictToPersisted
        displayType = settings.audiobooksDisplayType

        lazyLoader = .audiobooks(filtered: series.id, sortOrder: nil, ascending: nil)
        lazyLoader.didLoadMore = { [weak self] audiobooks in
            Task { @MainActor [weak self] in
                self?.updateHighlighted(provided: audiobooks)
            }
        }

        PersistenceManager.shared.progress.events.entityUpdated
            .sink { [weak self] connectionID, primaryID, groupingID, _ in
                Task { @MainActor [weak self] in
                    guard let self,
                          self.lazyLoader.items.contains(where: { $0.id.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) }) else {
                        return
                    }

                    self.updateHighlighted()
                }
            }
            .store(in: &observerSubscriptions)

        ItemEventSource.shared.updated
            .sink { [weak self] connectionID, primaryID, groupingID in
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }

                    if self.series.id.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) {
                        self.refresh()
                        return
                    }

                    if self.lazyLoader.items.contains(where: { $0.id.matchesItemUpdate(connectionID: connectionID, primaryID: primaryID, groupingID: groupingID) }) {
                        self.lazyLoader.refresh()
                        self.updateHighlighted()
                    }
                }
            }
            .store(in: &observerSubscriptions)
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

            if highlighted == .placeholder, lazyLoader.finished {
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
