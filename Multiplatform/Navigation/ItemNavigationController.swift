//
//  ItemNavigationController.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 08.01.26.
//

import SwiftUI
import ShelfPlayback

@MainActor @Observable
final class ItemNavigationController {
    var itemID: ItemIdentifier?
    var search: (String, SearchViewModel.SearchScope)?
    
    init() {
        RFNotification[.navigate].subscribe { [weak self] in
            self?.itemID = $0
        }
        RFNotification[.setGlobalSearch].subscribe { [weak self] in
            self?.search = $0
        }
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
