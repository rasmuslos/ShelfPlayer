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

@Observable @MainActor
final class LazyLoadHelper<T: Item, O: Sendable>: Sendable {
    private nonisolated static var PAGE_SIZE: Int { 100 }
    
    private(set) var items: [T]
    private(set) var count: Int
    
    var sortOrder: O
    var ascending: Bool
    
    private(set) var failed: Bool
    private(set) var working: Bool
    private(set) var finished: Bool
    
    var library: Library?
    
    private let loadMore: @Sendable (_ page: Int, _ sortOrder: O, _ ascending: Bool, _ library: Library) async throws -> ([T], Int)
    
    @MainActor
    init(sortOrder: O, ascending: Bool, loadMore: @Sendable @escaping (_ page: Int, _ sortOrder: O, _ ascending: Bool, _ library: Library) async throws -> ([T], Int)) {
        self.sortOrder = sortOrder
        self.ascending = ascending
        
        items = []
        count = 0
        
        failed = false
        working = false
        finished = false
        
        self.loadMore = loadMore
    }
    
    nonisolated func initialLoad() {
        didReachEndOfLoadedContent()
    }
    nonisolated func refresh() async {
        await MainActor.withAnimation { [self] in
            items = []
            count = 0
            
            failed = false
            working = true
            finished = false
        }
        
        didReachEndOfLoadedContent(bypassWorking: true)
    }
    
    nonisolated func didReachEndOfLoadedContent(bypassWorking: Bool = false) {
        Task {
            guard await !working || bypassWorking, await !finished, let library = await library else {
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
                let (received, totalCount) = try await loadMore(page, sortOrder, ascending, library)
                
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

extension LazyLoadHelper {
    static var audiobooks: LazyLoadHelper<Audiobook, AudiobookSortOrder> {
        .init(sortOrder: Defaults[.audiobooksSortOrder], ascending: Defaults[.audiobooksAscending], loadMore: { _, _, _, _ in
            // try await AudiobookshelfClient.shared.audiobooks(libraryID: $3, sortOrder: $1, ascending: $2, limit: PAGE_SIZE, page: $0)
            ([], 0)
        })
    }
    
    static func audiobooks(seriesID: ItemIdentifier) -> LazyLoadHelper<Audiobook, ()?> {
        .init(sortOrder: nil, ascending: true, loadMore: { page, _, _, _ in
            try await ABSClient[seriesID.connectionID].audiobooks(series: seriesID, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var series: LazyLoadHelper<Series, SeriesSortOrder> {
        .init(sortOrder: Defaults[.seriesSortOrder], ascending: Defaults[.seriesAscending], loadMore: {
            try await ABSClient[$3.connectionID].series(in: $3.id, sortOrder: $1, ascending: $2, limit: PAGE_SIZE, page: $0)
        })
    }
    
    static var podcasts: LazyLoadHelper<Podcast, Never?> {
        .init(sortOrder: nil, ascending: Defaults[.podcastsAscending], loadMore: { _, _, _, _ in
            // try await AudiobookshelfClient.shared.podcasts(libraryID: $3, limit: PAGE_SIZE, page: $0)
            ([], 0)
        })
    }
}
