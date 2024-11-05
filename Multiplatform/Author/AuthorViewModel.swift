//
//  AuthorViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.08.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

@Observable
internal final class AuthorViewModel {
    @MainActor private(set) var author: Author
    @MainActor var library: Library!
    
    @MainActor private(set) var _series: [Series]
    @MainActor private(set) var _audiobooks: [Audiobook]
    
    @MainActor internal var filter: ItemFilter {
        didSet {
            Defaults[.audiobooksFilter] = filter
        }
    }
    @MainActor internal var displayMode: ItemDisplayType {
        didSet {
            Defaults[.audiobooksDisplay] = displayMode
        }
    }
    
    @MainActor var ascending: Bool
    @MainActor var sortOrder: AudiobookSortOrder
    
    @MainActor private(set) var collapseSeries: Bool
    
    @MainActor var descriptionSheetVisible: Bool
    @MainActor private(set) var errorNotify: Bool
    
    @MainActor
    init(author: Author, series: [Series], audiobooks: [Audiobook]) {
        self.author = author
        _series = series
        _audiobooks = audiobooks
        
        ascending = false
        sortOrder = .released
        
        filter = Defaults[.audiobooksFilter]
        displayMode = Defaults[.audiobooksDisplay]
        
        collapseSeries = Defaults[.collapseSeries]
        
        errorNotify = false
        descriptionSheetVisible = false
    }
    
    
}

internal extension AuthorViewModel {
    @MainActor
    var audiobooks: [AudiobookSection] {
        Audiobook.filterSort(_audiobooks, filter: filter, sortOrder: sortOrder, ascending: ascending).map { .audiobook(audiobook: $0) }
    }
    
    @MainActor
    var series: [Series] {
        guard !collapseSeries else {
            return []
        }
        
        return _series.sorted()
    }
    
    func load() async {
        guard let (author, audiobooks, series) = try? await AudiobookshelfClient.shared.author(authorId: author.id, libraryID: library.id) else {
            await MainActor.run {
                errorNotify.toggle()
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.author = author
            self._series = series
            self._audiobooks = audiobooks
        }
    }
}
