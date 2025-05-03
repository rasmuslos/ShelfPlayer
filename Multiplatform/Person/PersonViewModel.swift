//
//  AuthorViewModel.swift
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
final class PersonViewModel {
    let person: Person
    
    @ObservableDefault(.audiobooksFilter) @ObservationIgnored
    var filter: ItemFilter
    @ObservableDefault(.audiobooksRestrictToPersisted) @ObservationIgnored
    var restrictToPersisted: Bool
    @ObservableDefault(.audiobooksDisplayType) @ObservationIgnored
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
        
        notifyError = false
        
        audiobooksLoader = .audiobooks(filtered: person.id, sortOrder: .released, ascending: true)
        
        if person.id.type == .author {
            seriesLoader = .series(filtered: person.id, filter: Defaults[.audiobooksFilter], sortOrder: .sortName, ascending: true)
        }
    }
}

extension PersonViewModel {
    var sections: [AudiobookSection] {
        audiobooksLoader.items.map { .audiobook(audiobook: $0) }
    }
    
    nonisolated func load(refresh: Bool) {
        Task {
            await withTaskGroup(of: Void.self) {
                $0.addTask { await self.seriesLoader?.initialLoad() }
                $0.addTask { await self.audiobooksLoader.initialLoad() }
                
                if refresh {
                    $0.addTask {
                        try? await ShelfPlayer.refreshItem(itemID: self.person.id)
                        self.load(refresh: false)
                    }
                }
            }
        }
    }
}
