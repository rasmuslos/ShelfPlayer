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
final class AuthorViewModel {
    let author: Author
    
    @ObservableDefault(.audiobooksFilter) @ObservationIgnored
    var filter: ItemFilter
    @ObservableDefault(.audiobooksDisplayType) @ObservationIgnored
    var displayType: ItemDisplayType
    
    @ObservableDefault(.audiobooksSortOrder) @ObservationIgnored
    var sortOrder: AudiobookSortOrder
    @ObservableDefault(.audiobooksAscending) @ObservationIgnored
    var ascending: Bool
    
    // let seriesLoader: LazyLoadHelper<Series, Void?>
    var audiobooksLoader: LazyLoadHelper<Audiobook, AudiobookSortOrder?>!
    
    var library: Library! {
        didSet {
            audiobooksLoader.library = library
        }
    }
    
    var isDescriptionSheetVisible: Bool
    private(set) var notifyError: Bool
    
    @MainActor
    init(author: Author) {
        self.author = author
        
        isDescriptionSheetVisible = false
        notifyError = false
        
        audiobooksLoader = .audiobooks(filtered: author.id, sortOrder: sortOrder, ascending: ascending)
    }
}

extension AuthorViewModel {
    var sections: [AudiobookSection] {
        audiobooksLoader.items.map { .audiobook(audiobook: $0) }
    }
    
    nonisolated func load() {
        Task {
            await withTaskGroup(of: Void.self) {
                $0.addTask { await self.audiobooksLoader.initialLoad() }
            }
        }
    }
}
