//
//  LazyLoadHelper.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.09.24.
//

import Foundation
import SwiftUI
import OSLog
import ShelfPlayback

@Observable @MainActor
final class LazyLoadHelper<T, O>: Sendable where T: Sendable & Equatable & Identifiable, T.ID: Sendable, O: Sendable {
    private let logger: Logger
    
    private static var PAGE_SIZE: Int {
        #if DEBUG
        4
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
    
    private let loadMore: @Sendable (_ page: Int, _ filter: ItemFilter, _ sortOrder: O, _ ascending: Bool, _ groupAudiobooksInSeries: Bool, _ library: LibraryIdentifier) async throws -> ([T], Int)?
    var didLoadMore: ((@Sendable (_ current: [T]) -> Void)?)
    
    @MainActor
    init(filterLocally: Bool, filter: ItemFilter, restrictToPersisted: Bool, sortOrder: O, ascending: Bool, loadMore: @Sendable @escaping (_ page: Int, _ filter: ItemFilter, _ sortOrder: O, _ ascending: Bool, _ groupAudiobooksInSeries: Bool, _ library: LibraryIdentifier) async throws -> ([T], Int)?) {
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
        
        didLoadMore = nil
        
        Task { [weak self] in
            for await _ in Defaults.updates([.groupAudiobooksInSeries, .showSingleEntryGroupedSeries], initial: false) {
                self?.refresh()
            }
        }
    }
    // The app does not compile in release mode without this since Xcode 26.3
    deinit {}
    
    var didLoad: Bool {
        totalCount > 0
    }
    var isLoading: Bool {
        working && !finished
    }
        
    func initialLoad() {
        didReachEndOfLoadedContent()
    }
    func refresh() {
        Task {
            items = []
            
            loadedCount = 0
            totalCount = 0
            
            failed = false
            working = true
            finished = false
        }
        
        didReachEndOfLoadedContent(bypassWorking: true)
    }
    
    func didReachEndOfLoadedContent(bypassWorking: Bool = false) {
        Task { [weak self] in
            guard let self else {
                return
            }
            
            if working && !bypassWorking {
                return
            }
            
            working = true
            failed = false
            
            guard !finished else {
                return
            }
            
            guard let library = library else {
                #if DEBUG
                if self.items.isEmpty {
                    logger.warning("Library not set yet. Using fixtures.")
                    
                    if T.self == AudiobookSection.self {
                        self.items = Array(repeating: AudiobookSection.audiobook(audiobook: .fixture), count: 7) as! [T]
                    } else if T.self == Audiobook.self {
                        self.items = Array(repeating: Audiobook.fixture, count: 7) as! [T]
                    } else {
                        failed = true
                    }
                    
                    loadedCount = 7
                    totalCount = 7
                    
                    working = false
                    finished = true
                }
                #endif
                
                return
            }
            
            let loadedCount = loadedCount
            
            let page = loadedCount / Self.PAGE_SIZE
            let existingIDs = items.map(\.id)
            let filteredGenre = filteredGenre
            
            do {
                // MARK: Load
                
                var received: [T]
                let totalCount: Int
                
                let groupAudiobooksInSeries = Defaults[.groupAudiobooksInSeries]
                
                if let filteredGenre {
                    // Fuck you, this only needs to happen once, and this code is bloated already
                    (received, totalCount) = try await ABSClient[library.id.connectionID].audiobooks(from: library.id.libraryID, filtered: filteredGenre, sortOrder: sortOrder as! AudiobookSortOrder, ascending: ascending, groupSeries: groupAudiobooksInSeries, limit: Self.PAGE_SIZE, page: page) as! ([T], Int)
                } else if let response = try await loadMore(page, filter, sortOrder, ascending, groupAudiobooksInSeries, library.id) {
                    (received, totalCount) = response
                } else {
                    received = []
                    totalCount = self.totalCount
                }
                
                
                guard !received.isEmpty else {
                    withAnimation {
                        finished = true
                        working = false
                    }
                    
                    logger.info("Finished loading \(loadedCount) items of type \(T.self, privacy: .public)")
                    return
                }
                
                await Task.yield()
                
                let receivedCount = received.count
                received = received.filter { !existingIDs.contains($0.id) }
                
                if receivedCount < Self.PAGE_SIZE {
                    withAnimation {
                        finished = true
                    }
                    
                    logger.info("Finished loading items of type \(T.self, privacy: .public)")
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
                
                let filter = filter
                let filterLocally = filterLocally || filteredGenre != nil
                
                if restrictToPersisted {
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
                                case .series(let seriesID, let name, let audiobookIDs):
                                    var included = [ItemIdentifier]()
                                    
                                    for audiobookID in audiobookIDs {
                                        let status = await PersistenceManager.shared.download.status(of: audiobookID)
                                        
                                        if status != .none {
                                            included.append(audiobookID)
                                        }
                                    }
                                    
                                    if !included.isEmpty {
                                        filtered.append(.series(seriesID: seriesID, seriesName: name, audiobookIDs: included))
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
                    } else if let sections = received as? [AudiobookSection] {
                        var filtered = [AudiobookSection]()
                        
                        for section in sections {
                            switch section {
                                case .audiobook(let audiobook):
                                    if await audiobook.isIncluded(in: filter) {
                                        filtered.append(section)
                                    }
                                case .series(let seriesID, let seriesName, let audiobookIDs):
                                    var passed = [ItemIdentifier]()
                                    
                                    for audiobookID in audiobookIDs {
                                        let progress = await PersistenceManager.shared.progress[audiobookID].progress
                                        
                                        switch filter {
                                            case .all:
                                                passed.append(audiobookID)
                                            case .active:
                                                if progress > 0 && progress < 1 {
                                                    passed.append(audiobookID)
                                                }
                                            case .finished:
                                                if progress >= 1 {
                                                    passed.append(audiobookID)
                                                }
                                            case .notFinished:
                                                if progress < 1 {
                                                    passed.append(audiobookID)
                                                }
                                        }
                                    }
                                    
                                    guard !passed.isEmpty else {
                                        continue
                                    }
                                    
                                    filtered.append(.series(seriesID: seriesID, seriesName: seriesName, audiobookIDs: passed))
                            }
                        }
                        
                        received = filtered as! [T]
                    } else if let series = received as? [Series] {
                        var filtered = [Series]()
                        
                        for series in series {
                            var passed = [Audiobook]()
                            
                            for audiobook in series.audiobooks {
                                let progress = await PersistenceManager.shared.progress[audiobook.id].progress
                                
                                switch filter {
                                    case .all:
                                        passed.append(audiobook)
                                    case .active:
                                        if progress > 0 && progress < 1 {
                                            passed.append(audiobook)
                                        }
                                    case .finished:
                                        if progress >= 1 {
                                            passed.append(audiobook)
                                        }
                                    case .notFinished:
                                        if progress < 1 {
                                            passed.append(audiobook)
                                        }
                                }
                            }
                            
                            guard !passed.isEmpty else {
                                continue
                            }
                            
                            filtered.append(Series(id: series.id, name: series.name, authors: series.authors, description: series.description, addedAt: series.addedAt, audiobooks: passed))
                        }
                        
                        received = filtered as! [T]
                    } else {
                        throw LazyLoadError.unsupportedItemType
                    }
                }
                
                if let series = received as? [Series] {
                    var filtered = [Series]()
                    
                    for series in series {
                        var passed = [Audiobook]()
                        
                        for audiobook in series.audiobooks {
                            let progress = await PersistenceManager.shared.progress[audiobook.id].progress
                            
                            switch filter {
                                case .all:
                                    passed.append(audiobook)
                                case .active:
                                    if progress > 0 && progress < 1 {
                                        passed.append(audiobook)
                                    }
                                case .finished:
                                    if progress >= 1 {
                                        passed.append(audiobook)
                                    }
                                case .notFinished:
                                    if progress < 1 {
                                        passed.append(audiobook)
                                    }
                            }
                        }
                        
                        guard !passed.isEmpty else {
                            continue
                        }
                        
                        filtered.append(.init(id: series.id, name: series.name, authors: series.authors, description: series.description, addedAt: series.addedAt, audiobooks: passed))
                    }
                    
                    received = filtered as! [T]
                }
                
                let search = search.trimmingCharacters(in: .whitespacesAndNewlines)
                
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
                
                withAnimation {
                    working = false
                    
                    self.totalCount = totalCount
                    self.loadedCount += receivedCount
                    
                    items += received
                    
                    logger.info("Now at \(self.loadedCount)/\(self.totalCount) items of type \(T.self, privacy: .public) (received \(receivedCount))")
                }
                
                if let didLoadMore = didLoadMore {
                    didLoadMore(items)
                }
                
                // The filter has removed all new items so the method will not be called from the view
                
                if received.isEmpty {
                    didReachEndOfLoadedContent()
                }
            } catch {
                logger.error("Error loading more \(T.self, privacy: .public): \(error, privacy: .public)")
                
                notifyError.toggle()
                
                withAnimation {
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
            try await ABSClient[library.connectionID].audiobooks(from: library.libraryID, filter: filter, sortOrder: sortOrder, ascending: ascending, groupSeries: groupAudiobooksInSeries, limit: PAGE_SIZE, page: page)
        })
    }
    
    static func audiobooks(filtered: ItemIdentifier, sortOrder: AudiobookSortOrder?, ascending: Bool?) -> LazyLoadHelper<Audiobook, AudiobookSortOrder?> {
        .init(filterLocally: true, filter: Defaults[.audiobooksFilter], restrictToPersisted: Defaults[.audiobooksRestrictToPersisted], sortOrder: sortOrder, ascending: ascending ?? true, loadMore: { page, filter, sortOrder, ascending, _, _ in
            try await ABSClient[filtered.connectionID].audiobooks(filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var authors: LazyLoadHelper<Person, AuthorSortOrder> {
        .init(filterLocally: false, filter: .all, restrictToPersisted: false, sortOrder: Defaults[.authorsSortOrder], ascending: Defaults[.authorsAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].authors(from: library.libraryID, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    static var narrators: LazyLoadHelper<Person, NarratorSortOrder> {
        .init(filterLocally: false, filter: .all, restrictToPersisted: false, sortOrder: Defaults[.narratorsSortOrder], ascending: Defaults[.narratorsAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            guard page == 0 else {
                return nil
            }
            
            let narrators = try await ABSClient[library.connectionID].narrators(from: library.libraryID).sorted {
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
        .init(filterLocally: false, filter: Defaults[.audiobooksFilter], restrictToPersisted: false, sortOrder: Defaults[.seriesSortOrder], ascending: Defaults[.seriesAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].series(in: library.libraryID, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static func series(filtered: ItemIdentifier, filter: ItemFilter, sortOrder: SeriesSortOrder, ascending: Bool) -> LazyLoadHelper<Series, SeriesSortOrder> {
        .init(filterLocally: true, filter: filter, restrictToPersisted: false, sortOrder: sortOrder, ascending: ascending, loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].series(in: library.libraryID, filtered: filtered, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static var podcasts: LazyLoadHelper<Podcast, PodcastSortOrder> {
        .init(filterLocally: false, filter: .all, restrictToPersisted: false, sortOrder: Defaults[.podcastsSortOrder], ascending: Defaults[.podcastsAscending], loadMore: { page, _, sortOrder, ascending, _, library in
            try await ABSClient[library.connectionID].podcasts(from: library.libraryID, sortOrder: sortOrder, ascending: ascending, limit: PAGE_SIZE, page: page)
        })
    }
    
    static func collections(_ type: ItemCollection.CollectionType) -> LazyLoadHelper<ItemCollection, Void?> {
        .init(filterLocally: false, filter: .all, restrictToPersisted: false, sortOrder: nil, ascending: true, loadMore: { page, _, _, _, _, library in
            try await ABSClient[library.connectionID].collections(in: library.libraryID, type: type, limit: PAGE_SIZE, page: page)
        })
    }
}
