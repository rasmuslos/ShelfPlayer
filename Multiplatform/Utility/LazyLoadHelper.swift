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
        10
        #else
        100
        #endif
    }
    
    private(set) var items: [T]
    
    private(set) var totalCount: Int
    private(set) var loadedCount: Int
    
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
    
    private var collapseSeries: Bool
    
    private(set) var failed: Bool
    private(set) var notifyError: Bool
    
    private(set) var working: Bool
    private(set) var finished: Bool
    
    var library: Library?
    
    private var lastTriggerIndex: Int?
    private let loadMore: @Sendable (_ page: Int, _ sortOrder: O, _ ascending: Bool, _ collapseSeries: Bool, _ library: Library) async throws -> ([T], Int)
    
    @MainActor
    init(filter: ItemFilter, sortOrder: O, ascending: Bool, loadMore: @Sendable @escaping (_ page: Int, _ sortOrder: O, _ ascending: Bool, _ collapseSeries: Bool, _ library: Library) async throws -> ([T], Int)) {
        logger = .init(subsystem: "io.rfk.shelfPlayer", category: "LazyLoader")
        
        self.filter = filter
        
        self.sortOrder = sortOrder
        self.ascending = ascending
        
        collapseSeries = Defaults[.collapseSeries]
        
        items = []
        
        totalCount = 0
        loadedCount = 0
        
        failed = false
        notifyError = false
        
        working = false
        finished = false
        
        self.loadMore = loadMore
        
        Task {
            for await collapseSeries in Defaults.updates(.collapseSeries) {
                guard self.collapseSeries != collapseSeries else {
                    return
                }
                
                self.collapseSeries = collapseSeries
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
    nonisolated func refresh(resetCount: Bool = true) {
        Task { @MainActor in
            items = []
            
            loadedCount = 0
            
            if resetCount {
                totalCount = 0
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
            
            let loadedCount = await loadedCount
            
            guard loadedCount % Self.PAGE_SIZE == 0 else {
                await MainActor.withAnimation { [self] in
                    finished = true
                }
                
                logger.info("Finished loading \(loadedCount) items of type \(T.self)")
                return
            }
            
            let page = loadedCount / Self.PAGE_SIZE
            let existingIDs = await items.map(\.id)
            
            do {
                var (received, totalCount) = try await loadMore(page, sortOrder, ascending, collapseSeries, library)
                
                await Task.yield()
                
                received = received.filter { !existingIDs.contains($0.id) }
                
                let filter = await filter
                let receivedCount = received.count
                
                if filter != .all {
                    if let items = received as? [PlayableItem] {
                        var filtered = [PlayableItem]()
                        
                        for item in items {
                            if await item.id.isIncluded(in: filter) {
                                filtered.append(item)
                            }
                        }
                        
                        received = filtered as! [T]
                    } else if let sections = received as? [AudiobookSection] {
                        var filtered = [AudiobookSection]()
                        
                        for section in sections {
                            switch section {
                            case .audiobook(let audiobook):
                                if await audiobook.id.isIncluded(in: filter) {
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
                
                if received.isEmpty && receivedCount > 0 {
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
        
        if let lastTriggerIndex {
            if index < lastTriggerIndex + Int(Double(Self.PAGE_SIZE) * 0.7) {
                return
            }
        }
        
        lastTriggerIndex = index
        
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
        .init(filter: Defaults[.audiobooksFilter], sortOrder: Defaults[.audiobooksSortOrder], ascending: Defaults[.audiobooksAscending], loadMore: {
            try await ABSClient[$4.connectionID].audiobooks(from: $4.id, sortOrder: $1, ascending: $2, groupSeries: $3, limit: PAGE_SIZE, page: $0)
        })
    }
    
    static func audiobooks(filtered: ItemIdentifier, sortOrder: AudiobookSortOrder?, ascending: Bool?) -> LazyLoadHelper<Audiobook, AudiobookSortOrder?> {
        .init(filter: Defaults[.audiobooksFilter], sortOrder: sortOrder, ascending: ascending ?? true, loadMore: { page, sortOrder, ascending, _, _ in
            try await ABSClient[filtered.connectionID].audiobooks(filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var series: LazyLoadHelper<Series, SeriesSortOrder> {
        .init(filter: .all, sortOrder: Defaults[.seriesSortOrder], ascending: Defaults[.seriesAscending], loadMore: {
            try await ABSClient[$4.connectionID].series(in: $4.id, sortOrder: $1, ascending: $2, limit: PAGE_SIZE, page: $0)
        })
    }
    
    static func series(filtered: ItemIdentifier, sortOrder: SeriesSortOrder, ascending: Bool) -> LazyLoadHelper<Series, SeriesSortOrder> {
        .init(filter: .all, sortOrder: sortOrder, ascending: ascending, loadMore: { page, sortOrder, ascending, _, library in
            try await ABSClient[filtered.connectionID].series(in: library.id, filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var podcasts: LazyLoadHelper<Podcast, Never?> {
        .init(filter: .all, sortOrder: nil, ascending: Defaults[.podcastsAscending], loadMore: { _, _, _, _, _ in
            // try await AudiobookshelfClient.shared.podcasts(libraryID: $3, limit: PAGE_SIZE, page: $0)
            ([], 0)
        })
    }
}
