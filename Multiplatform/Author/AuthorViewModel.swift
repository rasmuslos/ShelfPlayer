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
    
    @MainActor private(set) var series = [Series]()
    @MainActor private(set) var audiobooks = [Audiobook]()
    
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
    
    @MainActor private(set) var errorNotify: Bool
    @MainActor var descriptionSheetVisible: Bool
    
    @MainActor
    init(author: Author, series: [Series], audiobooks: [Audiobook]) {
        self.author = author
        self.series = series
        self.audiobooks = audiobooks
        
        ascending = false
        sortOrder = .released
        
        filter = Defaults[.audiobooksFilter]
        displayMode = Defaults[.audiobooksDisplay]
        
        errorNotify = false
        descriptionSheetVisible = false
    }
}

internal extension AuthorViewModel {
    @MainActor
    var visible: [Audiobook] {
        AudiobookSortFilter.filterSort(audiobooks: audiobooks, filter: filter, order: sortOrder, ascending: ascending)
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
            self.series = series
            self.audiobooks = audiobooks
        }
    }
}
