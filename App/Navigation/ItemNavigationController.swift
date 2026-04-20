//
//  ItemNavigationController.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 08.01.26.
//

import SwiftUI
import Combine
import ShelfPlayback

@MainActor @Observable
final class ItemNavigationController {
    private var observerSubscriptions = Set<AnyCancellable>()

    var itemID: ItemIdentifier?
    var search: (String, SearchViewModel.SearchScope)?

    init() {
        NavigationEventSource.shared.navigate
            .sink { [weak self] itemID in
                Task { @MainActor [weak self] in
                    self?.itemID = itemID
                }
            }
            .store(in: &observerSubscriptions)
        NavigationEventSource.shared.setGlobalSearch
            .sink { [weak self] search in
                Task { @MainActor [weak self] in
                    self?.search = search
                }
            }
            .store(in: &observerSubscriptions)
    }

    func consume() -> ItemIdentifier? {
        let itemID = self.itemID
        self.itemID = nil

        return itemID
    }
    func consume() -> (String, SearchViewModel.SearchScope)? {
        let search = self.search
        self.search = nil

        return search
    }
}
