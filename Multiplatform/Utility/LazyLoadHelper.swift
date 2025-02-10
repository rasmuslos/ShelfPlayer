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
import DefaultsMacros
import ShelfPlayerKit

@Observable @MainActor
final class LazyLoadHelper<T, O>: Sendable where T: Sendable & Equatable & Identifiable, O: Sendable {
    private let logger: Logger
    
    private nonisolated static var PAGE_SIZE: Int {
        #if DEBUG
        30
        #else
        100
        #endif
    }
    
    private(set) var items: [T]
    
    private(set) var totalCount: Int
    private(set) var loadedCount: Int
    
    var filter: ItemFilter {
        didSet {
            refresh()
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
    
    private var groupAudiobooksInSeries: Bool
    private let filterLocally: Bool
    
    var filteredGenre: String? {
        didSet {
            refresh()
        }
    }
    
    private(set) var failed: Bool
    private(set) var notifyError: Bool
    
    private(set) var working: Bool
    private(set) var finished: Bool
    
    var library: Library?
    
    private let loadMore: @Sendable (_ page: Int, _ filter: ItemFilter, _ sortOrder: O, _ ascending: Bool, _ collapseSeries: Bool, _ library: Library) async throws -> ([T], Int)
    
    @MainActor
    init(filterLocally: Bool, filter: ItemFilter, sortOrder: O, ascending: Bool, loadMore: @Sendable @escaping (_ page: Int, _ filter: ItemFilter, _ sortOrder: O, _ ascending: Bool, _ collapseSeries: Bool, _ library: Library) async throws -> ([T], Int)) {
        logger = .init(subsystem: "io.rfk.shelfPlayer", category: "LazyLoader")
        
        self.filter = filter
        
        self.sortOrder = sortOrder
        self.ascending = ascending
        
        groupAudiobooksInSeries = Defaults[.groupAudiobooksInSeries]
        self.filterLocally = filterLocally
        
        items = []
        
        totalCount = 0
        loadedCount = 0
        
        filteredGenre = nil
        
        failed = false
        notifyError = false
        
        working = false
        finished = false
        
        self.loadMore = loadMore
        
        Task {
            for await groupAudiobooksInSeries in Defaults.updates(.groupAudiobooksInSeries) {
                guard self.groupAudiobooksInSeries != groupAudiobooksInSeries else {
                    return
                }
                
                self.groupAudiobooksInSeries = groupAudiobooksInSeries
                refresh()
            }
        }
    }
    
    var didLoad: Bool {
        totalCount > 0
    }
    
    nonisolated func initialLoad() {
        didReachEndOfLoadedContent()
    }
    nonisolated func refresh() {
        Task { @MainActor in
            items = []
            
            loadedCount = 0
            totalCount = 0
            
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
            
            let loadedCount = await loadedCount
            
            let page = loadedCount / Self.PAGE_SIZE
            let existingIDs = await items.map(\.id)
            let filteredGenre = await filteredGenre
            
            do {
                var received: [T]
                let totalCount: Int
                
                if let filteredGenre {
                    // Fuck you, this only needs to happen once, and this code is bloated already
                    (received, totalCount) = try await ABSClient[library.connectionID].audiobooks(from: library.id, filtered: filteredGenre, sortOrder: sortOrder as! AudiobookSortOrder, ascending: ascending, groupSeries: groupAudiobooksInSeries, limit: Self.PAGE_SIZE, page: page) as! ([T], Int)
                } else {
                    (received, totalCount) = try await loadMore(page, filter, sortOrder, ascending, groupAudiobooksInSeries, library)
                }
                
                guard !received.isEmpty else {
                    await MainActor.withAnimation { [self] in
                        finished = true
                    }
                    
                    logger.info("Finished loading \(loadedCount) items of type \(T.self)")
                    return
                }
                
                await Task.yield()
                
                received = received.filter { !existingIDs.contains($0.id) }
                
                let filter = await filter
                
                let receivedCount = received.count
                let filterLocally = filterLocally || filteredGenre != nil
                
                if receivedCount < Self.PAGE_SIZE {
                    await MainActor.withAnimation { [self] in
                        finished = true
                    }
                    
                    logger.info("Finished loading items of type \(T.self)")
                }
                
                if filterLocally && filter != .all {
                    if let items = received as? [PlayableItem] {
                        var filtered = [PlayableItem]()
                        
                        for item in items {
                            if await item.isIncluded(in: filter) {
                                filtered.append(item)
                            }
                        }
                        
                        received = filtered as! [T]
                    } else if let series = received as? [Series] {
                        var filtered = [Series]()
                        
                        for series in series {
                            if await series.isIncluded(in: filter) {
                                filtered.append(series)
                            }
                        }
                        
                        received = filtered as! [T]
                    } else if let sections = received as? [AudiobookSection] {
                        var filtered = [AudiobookSection]()
                        
                        for section in sections {
                            switch section {
                            case .audiobook(let audiobook):
                                if await audiobook.isIncluded(in: filter) {
                                    filtered.append(section)
                                }
                            case .series(_, _, let audiobookIDs):
                                var progress = [Percentage]()
                                
                                for audiobookID in audiobookIDs {
                                    progress.append(await PersistenceManager.shared.progress[audiobookID].progress)
                                }
                                
                                let passed: Bool
                                
                                switch filter {
                                case .all:
                                    passed = true
                                case .active:
                                    passed = progress.reduce(false) { $0 || ($1 > 0 && $1 < 1) }
                                case .finished:
                                    passed = progress.allSatisfy { $0 >= 1 }
                                case .notFinished:
                                    passed = progress.reduce(false) { $0 || $1 < 1 }
                                }
                                
                                if passed {
                                    filtered.append(section)
                                }
                            }
                        }
                        
                        received = filtered as! [T]
                    } else {
                        throw FilterError.unsupportedItemType
                    }
                }
                
                await MainActor.withAnimation { [self] in
                    working = false
                    
                    self.totalCount = totalCount
                    self.loadedCount += receivedCount
                    
                    items += received
                    
                    logger.info("Now at \(self.loadedCount)/\(self.totalCount) items of type \(T.self) (received \(receivedCount))")
                }
                
                // The filter has removed all new items so the method will not be called from the view
                
                if received.isEmpty {
                    didReachEndOfLoadedContent()
                }
            } catch {
                logger.error("Error loading more \(T.self): \(error)")
                
                await MainActor.withAnimation { [self] in
                    notifyError.toggle()
                    
                    failed = true
                    working = false
                }
            }
        }
    }
    
    func performLoadIfRequired<K>(_ t: K, in array: [K]? = nil) where K: Equatable {
        let array = array ?? (items as! [K])
        guard let index = array.firstIndex(where: { $0 == t }) else { return }
        
        let thresholdIndex = array.index(items.endIndex, offsetBy: -10)
        
        if index < thresholdIndex {
            return
        }
        
        didReachEndOfLoadedContent()
    }
    
    enum FilterError: Error {
        case unsupportedItemType
    }
}

extension LazyLoadHelper {
    static var audiobooks: LazyLoadHelper<AudiobookSection, AudiobookSortOrder> {
        .init(filterLocally: false,
              filter: Defaults[.audiobooksFilter],
              sortOrder: Defaults[.audiobooksSortOrder],
              ascending: Defaults[.audiobooksAscending],
              loadMore: { page, filter, sortOrder, ascending, collapseSeries, library in
            try await ABSClient[library.connectionID].audiobooks(from: library.id, filter: filter, sortOrder: sortOrder, ascending: ascending, groupSeries: collapseSeries, limit: PAGE_SIZE, page: page)
        })
    }
    
    static func audiobooks(filtered: ItemIdentifier, sortOrder: AudiobookSortOrder?, ascending: Bool?) -> LazyLoadHelper<Audiobook, AudiobookSortOrder?> {
        .init(filterLocally: true, filter: Defaults[.audiobooksFilter], sortOrder: sortOrder, ascending: ascending ?? true, loadMore: { page, filter, sortOrder, ascending, _, _ in
            try await ABSClient[filtered.connectionID].audiobooks(filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var authors: LazyLoadHelper<Author, AuthorSortOrder> {
        .init(filterLocally: false, filter: .all, sortOrder: Defaults[.authorsSortOrder], ascending: Defaults[.authorsAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].authors(from: library.id, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var series: LazyLoadHelper<Series, SeriesSortOrder> {
        .init(filterLocally: false, filter: .all, sortOrder: Defaults[.seriesSortOrder], ascending: Defaults[.seriesAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].series(in: library.id, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static func series(filtered: ItemIdentifier, filter: ItemFilter, sortOrder: SeriesSortOrder, ascending: Bool) -> LazyLoadHelper<Series, SeriesSortOrder> {
        .init(filterLocally: true, filter: filter, sortOrder: sortOrder, ascending: ascending, loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].series(in: library.id, filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var podcasts: LazyLoadHelper<Podcast, Never?> {
        .init(filterLocally: false, filter: .all, sortOrder: nil, ascending: Defaults[.podcastsAscending], loadMore: { _, _, _, _, _, _ in
            // try await AudiobookshelfClient.shared.podcasts(libraryID: $3, limit: PAGE_SIZE, page: $0)
            ([], 0)
        })
    }
}
