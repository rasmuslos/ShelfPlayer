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
    var restrictToPersisted: Bool {
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
    
    private let filterLocally: Bool
    
    var search: String {
        didSet {
            searchTask?.cancel()
            searchTask = Task {
                try await Task.sleep(for: .milliseconds(750))
                try Task.checkCancellation()
                
                refresh()
            }
        }
    }
    var filteredGenre: String? {
        didSet {
            refresh()
        }
    }
    
    var searchTask: Task<Void, Error>?
    
    private(set) var failed: Bool
    private(set) var notifyError: Bool
    
    private(set) var working: Bool
    private(set) var finished: Bool
    
    var library: Library?
    
    private let loadMore: @Sendable (_ page: Int, _ filter: ItemFilter, _ sortOrder: O, _ ascending: Bool, _ groupAudiobooksInSeries: Bool, _ library: Library) async throws -> ([T], Int)?
    
    @MainActor
    init(filterLocally: Bool, filter: ItemFilter, restrictToPersisted: Bool, sortOrder: O, ascending: Bool, loadMore: @Sendable @escaping (_ page: Int, _ filter: ItemFilter, _ sortOrder: O, _ ascending: Bool, _ groupAudiobooksInSeries: Bool, _ library: Library) async throws -> ([T], Int)?) {
        logger = .init(subsystem: "io.rfk.shelfPlayer", category: "LazyLoader")
        
        self.filter = filter
        self.restrictToPersisted = restrictToPersisted
        
        self.sortOrder = sortOrder
        self.ascending = ascending
        
        self.filterLocally = filterLocally
        
        items = []
        
        totalCount = 0
        loadedCount = 0
        
        search = ""
        filteredGenre = nil
        
        failed = false
        notifyError = false
        
        working = false
        finished = false
        
        self.loadMore = loadMore
        
        Task {
            for await _ in Defaults.updates([.groupAudiobooksInSeries, .showSingleEntryGroupedSeries], initial: false) {
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
            guard let library = await library else {
                #if DEBUG
                if await self.items.isEmpty {
                    logger.warning("Library not set yet. Using fixtures.")
                    
                    await MainActor.run {
                        if T.self == AudiobookSection.self {
                            self.items = Array(repeating: AudiobookSection.audiobook(audiobook: .fixture), count: 7) as! [T]
                        } else {
                            failed = true
                        }
                        
                        self.loadedCount = 7
                        totalCount = 7
                        
                        working = false
                        finished = true
                    }
                }
                #endif
                
                return
            }
            
            let shouldContinue = await MainActor.run {
                if working {
                    return bypassWorking && !finished
                }
                
                working = true
                failed = false
                
                return !finished
            }
            
            guard shouldContinue else {
                return
            }
            
            let loadedCount = await loadedCount
            
            let page = loadedCount / Self.PAGE_SIZE
            let existingIDs = await items.map(\.id)
            let filteredGenre = await filteredGenre
            
            do {
                // MARK: Load
                
                var received: [T]
                let totalCount: Int
                
                let groupAudiobooksInSeries = Defaults[.groupAudiobooksInSeries]
                
                if let filteredGenre {
                    // Fuck you, this only needs to happen once, and this code is bloated already
                    (received, totalCount) = try await ABSClient[library.connectionID].audiobooks(from: library.id, filtered: filteredGenre, sortOrder: sortOrder as! AudiobookSortOrder, ascending: ascending, groupSeries: groupAudiobooksInSeries, limit: Self.PAGE_SIZE, page: page) as! ([T], Int)
                } else if let response = try await loadMore(page, filter, sortOrder, ascending, groupAudiobooksInSeries, library) {
                    (received, totalCount) = response
                } else {
                    received = []
                    totalCount = await self.totalCount
                }
                
                
                guard !received.isEmpty else {
                    await MainActor.withAnimation { [self] in
                        finished = true
                        working = false
                    }
                    
                    logger.info("Finished loading \(loadedCount) items of type \(T.self)")
                    return
                }
                
                await Task.yield()
                
                let receivedCount = received.count
                received = received.filter { !existingIDs.contains($0.id) }
                
                if receivedCount < Self.PAGE_SIZE {
                    await MainActor.withAnimation { [self] in
                        finished = true
                    }
                    
                    logger.info("Finished loading items of type \(T.self)")
                }
                
                // MARK: Replace audiobook sections with only one book
                
                if Defaults[.showSingleEntryGroupedSeries], let sections = received as? [AudiobookSection] {
                    var updated = [AudiobookSection]()
                    
                    for section in sections {
                        switch section {
                        case .audiobook:
                            updated.append(section)
                        case .series(_, _, let audiobookIDs):
                            guard audiobookIDs.count > 1 else {
                                guard let firstID = audiobookIDs.first else {
                                    continue
                                }
                                
                                guard let audiobook = try? await firstID.resolved as? Audiobook else {
                                    updated.append(section)
                                    continue
                                }
                                
                                updated.append(.audiobook(audiobook: audiobook))
                                continue
                            }
                            
                            updated.append(section)
                        }
                    }
                    
                    received = updated as! [T]
                }
                
                // MARK: Local filter & search
                
                let filter = await filter
                let filterLocally = filterLocally || filteredGenre != nil
                
                if await restrictToPersisted {
                    if let items = received as? [PlayableItem] {
                        var filtered = [PlayableItem]()
                        
                        for item in items {
                            let status = await PersistenceManager.shared.download.status(of: item.id)
                            
                            if status != .none {
                                filtered.append(item)
                            }
                        }
                        
                        received = filtered as! [T]
                    } else if let sections = received as? [AudiobookSection] {
                        var filtered = [AudiobookSection]()
                        
                        for section in sections {
                            switch section {
                            case .audiobook(let audiobook):
                                let status = await PersistenceManager.shared.download.status(of: audiobook.id)
                                
                                if status != .none {
                                    filtered.append(section)
                                }
                            case .series(_, _, let audiobookIDs):
                                for audiobookID in audiobookIDs {
                                    let status = await PersistenceManager.shared.download.status(of: audiobookID)
                                    
                                    if status != .none {
                                        filtered.append(section)
                                        break
                                    }
                                }
                            }
                        }
                        
                        received = filtered as! [T]
                    } else {
                        throw LazyLoadError.unsupportedItemType
                    }
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
                        throw LazyLoadError.unsupportedItemType
                    }
                }
                
                let search = await search.trimmingCharacters(in: .whitespacesAndNewlines)
                
                if !search.isEmpty {
                    if let items = received as? [Item] {
                        received = items.filter {
                            $0.sortName.localizedCaseInsensitiveContains(search)
                            || $0.authors.reduce(false) { $0 || $1.localizedCaseInsensitiveContains(search) }
                        } as! [T]
                    } else {
                        throw LazyLoadError.unsupportedItemType
                    }
                }
                
                // MARK: Update
                
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
    
    enum LazyLoadError: Error {
        case unsupportedItemType
    }
}

extension LazyLoadHelper {
    static var audiobooks: LazyLoadHelper<AudiobookSection, AudiobookSortOrder> {
        .init(filterLocally: false,
              filter: Defaults[.audiobooksFilter],
              restrictToPersisted: Defaults[.audiobooksRestrictToPersisted],
              sortOrder: Defaults[.audiobooksSortOrder],
              ascending: Defaults[.audiobooksAscending],
              loadMore: { page, filter, sortOrder, ascending, groupAudiobooksInSeries, library in
            try await ABSClient[library.connectionID].audiobooks(from: library.id, filter: filter, sortOrder: sortOrder, ascending: ascending, groupSeries: groupAudiobooksInSeries, limit: PAGE_SIZE, page: page)
        })
    }
    
    static func audiobooks(filtered: ItemIdentifier, sortOrder: AudiobookSortOrder?, ascending: Bool?) -> LazyLoadHelper<Audiobook, AudiobookSortOrder?> {
        .init(filterLocally: true, filter: Defaults[.audiobooksFilter], restrictToPersisted: Defaults[.audiobooksRestrictToPersisted], sortOrder: sortOrder, ascending: ascending ?? true, loadMore: { page, filter, sortOrder, ascending, _, _ in
            try await ABSClient[filtered.connectionID].audiobooks(filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var authors: LazyLoadHelper<Person, AuthorSortOrder> {
        .init(filterLocally: false, filter: .all, restrictToPersisted: false, sortOrder: Defaults[.authorsSortOrder], ascending: Defaults[.authorsAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].authors(from: library.id, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    static var narrators: LazyLoadHelper<Person, NarratorSortOrder> {
        .init(filterLocally: false, filter: .all, restrictToPersisted: false, sortOrder: Defaults[.narratorsSortOrder], ascending: Defaults[.narratorsAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            guard page == 0 else {
                return nil
            }
            
            let narrators = try await ABSClient[library.connectionID].narrators(from: library.id).sorted {
                switch sortOrder {
                case .name:
                    $0.name.localizedStandardCompare($1.name) == (ascending ? .orderedAscending : .orderedDescending)
                case .bookCount:
                    ascending ? $0.bookCount > $1.bookCount : $0.bookCount < $1.bookCount
                }
            }
            
            return (narrators, narrators.count)
        })
    }
    
    static var series: LazyLoadHelper<Series, SeriesSortOrder> {
        .init(filterLocally: false, filter: .all, restrictToPersisted: false, sortOrder: Defaults[.seriesSortOrder], ascending: Defaults[.seriesAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].series(in: library.id, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static func series(filtered: ItemIdentifier, filter: ItemFilter, sortOrder: SeriesSortOrder, ascending: Bool) -> LazyLoadHelper<Series, SeriesSortOrder> {
        .init(filterLocally: true, filter: filter, restrictToPersisted: false, sortOrder: sortOrder, ascending: ascending, loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].series(in: library.id, filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var podcasts: LazyLoadHelper<Podcast, PodcastSortOrder> {
        .init(filterLocally: false, filter: .all, restrictToPersisted: false, sortOrder: Defaults[.podcastsSortOrder], ascending: Defaults[.podcastsAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].podcasts(from: library.id, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
}
