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
    
    private nonisolated static var PAGE_SIZE: Int {
        #if DEBUG
        10
        #else
        100
        #endif
    }
    
    private(set) var items: [T]
    private(set) var count: Int
    
    var filter: ItemFilter {
        didSet {
            refresh(resetCount: false)
        }
    }
    
    var sortOrder: O {
        didSet {
            refresh()
        }
    }
    var ascending: Bool {
        didSet {
            refresh()
        }
    }
    
    private(set) var failed: Bool
    private(set) var working: Bool
    private(set) var finished: Bool
    
    var library: Library?
    
    private let loadMore: @Sendable (_ page: Int, _ sortOrder: O, _ ascending: Bool, _ library: Library) async throws -> ([T], Int)
    
    @MainActor
    init(filter: ItemFilter, sortOrder: O, ascending: Bool, loadMore: @Sendable @escaping (_ page: Int, _ sortOrder: O, _ ascending: Bool, _ library: Library) async throws -> ([T], Int)) {
        logger = .init(subsystem: "io.rfk.shelfPlayer", category: "LazyLoader")
        
        self.filter = filter
        
        self.sortOrder = sortOrder
        self.ascending = ascending
        
        items = []
        count = 0
        
        failed = false
        working = false
        finished = false
        
        self.loadMore = loadMore
    }
    
    var didLoad: Bool {
        count > 0
    }
    
    nonisolated func initialLoad() {
        didReachEndOfLoadedContent()
    }
    nonisolated func refresh(resetCount: Bool = true) {
        Task { @MainActor in
            items = []
            
            if resetCount {
                count = 0
            }
            
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
                
                logger.info("Finished loading \(itemCount) items of type \(T.self)")
                
                return
            }
            
            let page = itemCount / Self.PAGE_SIZE
            
            do {
                var (received, totalCount) = try await loadMore(page, sortOrder, ascending, library)
                
                await Task.yield()
                let filter = await filter
                
                if filter != .all {
                    guard let items = received as? [PlayableItem] else {
                        throw FilterError.unsupportedItemType
                    }
                    
                    var filtered = [PlayableItem]()
                    
                    for item in items {
                        let included: Bool
                        let entity = await PersistenceManager.shared.progress[item.id]
                        
                        switch filter {
                        case .all:
                            included = true
                        case .active:
                            included = entity.progress > 0 && entity.progress < 1
                        case .finished:
                            included = entity.isFinished
                        case .notFinished:
                            included = !entity.isFinished
                        }
                        
                        if included {
                            filtered.append(item)
                        }
                    }
                    
                    received = filtered as! [T]
                }
                
                await MainActor.withAnimation { [self] in
                    items += received
                    count = totalCount
                    
                    working = false
                }
                
                logger.info("Received \(received.count)/\(totalCount) items of type \(T.self) (had \(itemCount))")
            } catch {
                logger.error("Error loading more \(T.self): \(error)")
                
                await MainActor.withAnimation { [self] in
                    failed = true
                }
            }
        }
    }
    
    func performLoadIfRequired<K>(_ t: K, in array: [K]? = nil) where K: Equatable {
        let array = array ?? (items as! [K])
        guard let index = array.firstIndex(where: { $0 == t }) else { return }
        
        let thresholdIndex = array.index(items.endIndex, offsetBy: -10)
        
        if index != thresholdIndex {
            return
        }
        
        didReachEndOfLoadedContent()
    }
    
    enum FilterError: Error {
        case unsupportedItemType
    }
}

extension LazyLoadHelper {
    static var audiobooks: LazyLoadHelper<Audiobook, AudiobookSortOrder> {
        .init(filter: Defaults[.audiobooksFilter], sortOrder: Defaults[.audiobooksSortOrder], ascending: Defaults[.audiobooksAscending], loadMore: { _, _, _, _ in
            // try await AudiobookshelfClient.shared.audiobooks(libraryID: $3, sortOrder: $1, ascending: $2, limit: PAGE_SIZE, page: $0)
            ([], 0)
        })
    }
    
    static func audiobooks(filtered: ItemIdentifier, sortOrder: AudiobookSortOrder?, ascending: Bool?) -> LazyLoadHelper<Audiobook, AudiobookSortOrder?> {
        .init(filter: Defaults[.audiobooksFilter], sortOrder: sortOrder, ascending: ascending ?? true, loadMore: { page, sortOrder, ascending, _ in
            try await ABSClient[filtered.connectionID].audiobooks(filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var series: LazyLoadHelper<Series, SeriesSortOrder> {
        .init(filter: .all, sortOrder: Defaults[.seriesSortOrder], ascending: Defaults[.seriesAscending], loadMore: {
            try await ABSClient[$3.connectionID].series(in: $3.id, sortOrder: $1, ascending: $2, limit: PAGE_SIZE, page: $0)
        })
    }
    
    static func series(filtered: ItemIdentifier, sortOrder: SeriesSortOrder, ascending: Bool) -> LazyLoadHelper<Series, SeriesSortOrder> {
        .init(filter: .all, sortOrder: sortOrder, ascending: ascending, loadMore: { page, sortOrder, ascending, library in
            try await ABSClient[filtered.connectionID].series(in: library.id, filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var podcasts: LazyLoadHelper<Podcast, Never?> {
        .init(filter: .all, sortOrder: nil, ascending: Defaults[.podcastsAscending], loadMore: { _, _, _, _ in
            // try await AudiobookshelfClient.shared.podcasts(libraryID: $3, limit: PAGE_SIZE, page: $0)
            ([], 0)
        })
    }
}
