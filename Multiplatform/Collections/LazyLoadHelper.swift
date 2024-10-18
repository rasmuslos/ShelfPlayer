//
//  LazyLoadHelper.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.09.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

@Observable
internal final class LazyLoadHelper<T: Item, O: Any> {
    private static var PAGE_SIZE: Int {
        100
    }
    
    @MainActor private(set) internal var items: [T]
    @MainActor private(set) internal var count: Int
    
    @MainActor internal var sortOrder: O
    @MainActor internal var ascending: Bool
    
    @MainActor private(set) internal var failed: Bool
    @MainActor private(set) internal var working: Bool
    @MainActor private(set) internal var finished: Bool
    
    @MainActor internal var library: Library!
    
    private let loadMore: (_ : Int, _ : O, _ : Bool, _ : String) async throws -> ([T], Int)
    
    @MainActor
    init(sortOrder: O, ascending: Bool, loadMore: @escaping (_: Int, _ : O, _ : Bool, _ : String) async throws -> ([T], Int)) {
        self.sortOrder = sortOrder
        self.ascending = ascending
        
        items = []
        count = 0
        
        failed = false
        working = false
        finished = false
        
        self.loadMore = loadMore
    }
    
    func initialLoad() {
        didReachEndOfLoadedContent()
    }
    func refresh() async {
        await MainActor.withAnimation { [self] in
            items = []
            count = 0
            
            failed = false
            working = true
            finished = false
        }
        
        didReachEndOfLoadedContent(bypassWorking: true)
    }
    
    func didReachEndOfLoadedContent(bypassWorking: Bool = false) {
        Task {
            guard await !working || bypassWorking, await !finished else {
                return
            }
            
            await MainActor.withAnimation { [self] in
                failed = false
                working = true
            }
            
            let itemCount = await items.count
            
            guard itemCount % Self.PAGE_SIZE == 0 else {
                await MainActor.withAnimation { [self] in
                    finished = true
                }
                
                return
            }
            
            let page = itemCount / Self.PAGE_SIZE
            
            do {
                let (received, totalCount) = try await loadMore(page, sortOrder, ascending, library.id)
                
                await MainActor.withAnimation { [self] in
                    items += received
                    count = totalCount
                    
                    working = false
                }
            } catch {
                await MainActor.withAnimation { [self] in
                    failed = true
                }
            }
        }
    }
}

internal extension LazyLoadHelper {
    @MainActor
    static var audiobooks: LazyLoadHelper<Audiobook, AudiobookSortOrder> {
        .init(sortOrder: Defaults[.audiobooksSortOrder], ascending: Defaults[.audiobooksAscending], loadMore: {
            try await AudiobookshelfClient.shared.audiobooks(libraryID: $3, sortOrder: $1, ascending: $2, limit: PAGE_SIZE, page: $0)
        })
    }
    
    @MainActor
    static func audiobooks(seriesID: String) -> LazyLoadHelper<Audiobook, AudiobookSortOrder> {
        .init(sortOrder: .series, ascending: true, loadMore: {
            try await AudiobookshelfClient.shared.audiobooks(seriesId: seriesID, libraryID: $3, sortOrder: $1, ascending: $2, limit: PAGE_SIZE, page: $0)
        })
    }
    
    @MainActor
    static var series: LazyLoadHelper<Series, Never?> {
        .init(sortOrder: nil, ascending: false, loadMore: {
            try await AudiobookshelfClient.shared.series(libraryID: $3, limit: PAGE_SIZE, page: $0)
        })
    }
    
    @MainActor
    static var podcasts: LazyLoadHelper<Podcast, Never?> {
        .init(sortOrder: nil, ascending: Defaults[.podcastsAscending], loadMore: {
            try await AudiobookshelfClient.shared.podcasts(libraryID: $3, limit: PAGE_SIZE, page: $0)
        })
    }
}
