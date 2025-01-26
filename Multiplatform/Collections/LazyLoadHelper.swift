//
//  LazyLoadHelper.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.09.24.
//

import Foundation
import SwiftUI
import OSLog
import Defaults
import ShelfPlayerKit

@Observable @MainActor
final class LazyLoadHelper<T: Sendable, O: Sendable>: Sendable {
    private let logger: Logger
    
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
        logger = .init(subsystem: "io.rfk.shelfPlayer", category: "LazyLoader")
        
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
        logger.info("Begin lazy loading \(T.self)")
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
                
                logger.info("Finished loading \(itemCount) \(T.self)s")
                
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
                
                logger.info("Received \(received.count) \(T.self)s out of \(totalCount) (had \(itemCount))")
            } catch {
                logger.error("Error loading more \(T.self): \(error)")
                
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
    
    static func audiobooks(filtered: ItemIdentifier, sortOrder: AudiobookSortOrder?, ascending: Bool?) -> LazyLoadHelper<Audiobook, AudiobookSortOrder?> {
        .init(sortOrder: sortOrder, ascending: ascending ?? true, loadMore: { page, sortOrder, ascending, _ in
            try await ABSClient[filtered.connectionID].audiobooks(filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var series: LazyLoadHelper<Series, SeriesSortOrder> {
        .init(sortOrder: Defaults[.seriesSortOrder], ascending: Defaults[.seriesAscending], loadMore: {
            try await ABSClient[$3.connectionID].series(in: $3.id, sortOrder: $1, ascending: $2, limit: PAGE_SIZE, page: $0)
        })
    }
    
    static func series(filtered: ItemIdentifier, sortOrder: SeriesSortOrder, ascending: Bool) -> LazyLoadHelper<Series, SeriesSortOrder> {
        .init(sortOrder: sortOrder, ascending: ascending, loadMore: { page, sortOrder, ascending, library in
            try await ABSClient[filtered.connectionID].series(in: library.id, filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var podcasts: LazyLoadHelper<Podcast, Never?> {
        .init(sortOrder: nil, ascending: Defaults[.podcastsAscending], loadMore: { _, _, _, _ in
            // try await AudiobookshelfClient.shared.podcasts(libraryID: $3, limit: PAGE_SIZE, page: $0)
            ([], 0)
        })
    }
}
