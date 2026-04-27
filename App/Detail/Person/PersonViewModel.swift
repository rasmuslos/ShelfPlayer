//
//  PersonViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.08.24.
//

import Foundation
import Combine
import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class PersonViewModel {
    private var observerSubscriptions = Set<AnyCancellable>()

    let person: Person

    var filter: ItemFilter
    var restrictToPersisted: Bool
    var displayType: ItemDisplayType

    private(set) var seriesLoader: LazyLoadHelper<Series, SeriesSortOrder>?
    private(set) var audiobooksLoader: LazyLoadHelper<Audiobook, AudiobookSortOrder?>

    var library: Library! {
        didSet {
            seriesLoader?.library = library
            audiobooksLoader.library = library
        }
    }

    private(set) var notifyError: Bool

    @MainActor
    init(person: Person) {
        self.person = person

        let settings = AppSettings.shared
        filter = settings.audiobooksFilter
        restrictToPersisted = settings.audiobooksRestrictToPersisted
        displayType = settings.audiobooksDisplayType

        notifyError = false

        audiobooksLoader = .audiobooks(filtered: person.id, sortOrder: .released, ascending: true)

        if person.id.type == .author {
            seriesLoader = .series(filtered: person.id, filter: settings.audiobooksFilter, sortOrder: .sortName, ascending: true)
        }

        ItemEventSource.shared.updated
            .sink { [weak self] connectionID, primaryID, groupingID in
                Task { @MainActor [weak self] in
                    guard let self else {
                        return
                    }

                    if self.person.id.isEqual(primaryID: primaryID, groupingID: groupingID, connectionID: connectionID) {
                        self.load(refresh: true)
                        return
                    }

                    let matchesContent = self.audiobooksLoader.items.contains { $0.id.matchesItemUpdate(connectionID: connectionID, primaryID: primaryID, groupingID: groupingID) }
                        || (self.seriesLoader?.items.contains { $0.id.matchesItemUpdate(connectionID: connectionID, primaryID: primaryID, groupingID: groupingID) } ?? false)

                    if matchesContent {
                        self.audiobooksLoader.refresh()
                        self.seriesLoader?.refresh()
                    }
                }
            }
            .store(in: &observerSubscriptions)
    }
}

extension PersonViewModel {
    var sections: [AudiobookSection] {
        audiobooksLoader.items.map { .audiobook(audiobook: $0) }
    }

    func load(refresh: Bool) {
        Task {
            await withTaskGroup(of: Void.self) {
                $0.addTask { await self.seriesLoader?.initialLoad() }
                $0.addTask { await self.audiobooksLoader.initialLoad() }
            }

            if refresh {
                try? await ShelfPlayer.refreshItem(itemID: self.person.id)
                self.load(refresh: false)
            }
        }
    }
}
