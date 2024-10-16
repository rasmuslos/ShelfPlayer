//
//  ViewModel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.08.24.
//

import Foundation
import SwiftUI
import Defaults
import RFKVisuals
import ShelfPlayerKit
import SPPlayback

internal extension NowPlaying {
    @Observable
    class ViewModel {
        // MARK: Presentation
        
        @ObservationIgnored var namespace: Namespace.ID!
        @MainActor var _dragOffset: CGFloat
        
        @MainActor private var _expanded: Bool
        
        // MARK: Sliders
        
        @MainActor var seekDragging: Bool
        @MainActor var volumeDragging: Bool
        @MainActor var controlsDragging: Bool
        
        @MainActor var draggedPercentage: Double
        
        // MARK: Current state
        
        @MainActor private(set) var item: PlayableItem?
        @MainActor private(set) var queue: [PlayableItem]
        
        @MainActor private(set) var playing: Bool
        
        @MainActor private(set) var itemDuration: Double
        @MainActor private(set) var itemCurrentTime: Double
        
        @MainActor private(set) var chapterDuration: Double
        @MainActor private(set) var chapterCurrentTime: Double
        
        @MainActor private(set) var playbackRate: Percentage
        
        @MainActor private(set) var chapter: PlayableItem.Chapter?
        @MainActor private(set) var chapters: [PlayableItem.Chapter]
        
        @MainActor private(set) var skipForwardsInterval: Int
        @MainActor private(set) var skipBackwardsInterval: Int
        
        @MainActor private(set) var buffering: Bool
        @MainActor private(set) var isUsingExternalRoute: Bool
        
        // MARK: Sleep timer
        
        @MainActor private(set) var remainingSleepTime: TimeInterval?
        @MainActor private(set) var sleepTimerExpiresAtChapterEnd: Bool
        
        // MARK: Sheet
        
        @MainActor var sheetTab: SheetTab?
        @MainActor var sheetPresented: Bool
        
        // MARK: Bookmarks
        
        @MainActor var bookmarks: [Bookmark]
        @MainActor var bookmarkNote: String
        
        @MainActor var bookmarkEditingIndex: Int?
        @MainActor var bookmarkCapturedTime: TimeInterval?
        
        // MARK: Helper
        
        @MainActor private(set) var notifyPlaying: Int
        @MainActor private(set) var notifyBookmark: Int
        
        @MainActor private(set) var notifyForwards: Int
        @MainActor private(set) var notifyBackwards: Int
        
        @MainActor private(set) var notifyError: Int
        
        @ObservationIgnored private var tokens = [Any]()
        
        @MainActor
        init() {
            namespace = nil
            _dragOffset = .zero
            
            _expanded = false
            
            seekDragging = false
            volumeDragging = false
            controlsDragging = false
            
            draggedPercentage = 0
            
            item = nil
            queue = []
            
            playing = false
            
            itemDuration = .zero
            itemCurrentTime = .zero
            
            chapterDuration = .zero
            chapterCurrentTime = .zero
            
            playbackRate = 1.0
            
            chapter = nil
            chapters = []
            
            skipForwardsInterval = Defaults[.skipForwardsInterval]
            skipBackwardsInterval = Defaults[.skipBackwardsInterval]
            
            buffering = false
            isUsingExternalRoute = false
            
            remainingSleepTime = nil
            sleepTimerExpiresAtChapterEnd = false
            
            bookmarks = []
            
            bookmarkNote = ""
            bookmarkCapturedTime = nil
            
            sheetTab = .chapters
            sheetPresented = false
            
            notifyPlaying = 0
            notifyBookmark = 0
            
            notifyForwards = 0
            notifyBackwards = 0
            
            notifyError = 0
            
            setupObservers()
        }
    }
    
    enum QueueTab: Hashable, Identifiable, Equatable, CaseIterable {
        case history
        case queue
        case infiniteQueue
        
        var id: Self {
            self
        }
    }
}

// MARK: Properties

internal extension NowPlaying.ViewModel {
    @MainActor
    var expanded: Bool {
        get {
            if item == nil {
                return false
            }
            
            return _expanded
        }
        set {
            Task { @MainActor in
                if newValue {
                    dragOffset = 0
                }
                
                UIApplication.shared.isIdleTimerDisabled = newValue
                _expanded = newValue
            }
        }
    }
    @MainActor
    var dragOffset: CGFloat {
        get {
            if !expanded || controlsDragging || _dragOffset < 10 {
                return 0
            }
            
            return _dragOffset
        }
        set {
            self._dragOffset = newValue
        }
    }
    
    @MainActor
    var backgroundCornerRadius: CGFloat {
        guard expanded else {
            return 16
        }
        
        if dragOffset > 0 {
            return UIScreen.main.displayCornerRadius
        }
        
        return 0
    }
    
    @MainActor
    var displayedProgress: Double {
        seekDragging ? draggedPercentage : playedPercentage
    }
    @MainActor
    var playedPercentage: Double {
        chapterCurrentTime / chapterDuration
    }
    
    @MainActor
    var remaining: TimeInterval {
        (chapterDuration - chapterCurrentTime) * (1 / .init(playbackRate))
    }
    @MainActor
    var played: Percentage {
        .init((AudioPlayer.shared.chapterCurrentTime / AudioPlayer.shared.chapterCurrentTime) * 100)
    }
    
    @MainActor
    var sheetLabelIcon: String {
        switch sheetTab {
        case .queue:
            "list.triangle"
        case .chapters:
            "list.number"
        case .bookmarks:
            "list.star"
        case .none:
            "loading"
        }
    }
    
    @MainActor
    var bookmarkTabVisible: Bool {
        item?.type == .audiobook
    }
    
    @MainActor
    var visibleSheetTabs: [SheetTab] {
        bookmarkTabVisible ? [.bookmarks, .chapters, .queue] : [.chapters, .queue]
    }
}

// MARK: Observers

private extension NowPlaying.ViewModel {
    // This is truly swift the way it was intended to be
    func setupObservers() {
        for token in tokens {
            NotificationCenter.default.removeObserver(token)
        }
        
        tokens = []
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.itemDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task {
                await MainActor.withAnimation { [weak self] in
                    let item = self?.item
                    
                    self?.item = AudioPlayer.shared.item
                    self?.chapters = AudioPlayer.shared.chapters
                    
                    self?.isUsingExternalRoute = AudioPlayer.shared.isUsingExternalRoute
                    
                    if item == nil && self?.item?.type == .audiobook {
                        self?.expanded = true
                    } else if self?.item == nil {
                        self?.expanded = false
                    }
                }
                
                await self?.updateBookmarks()
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.playingDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.playing = AudioPlayer.shared.playing
                self?.notifyPlaying += 1
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.chapterDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.chapter = AudioPlayer.shared.chapter
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.chaptersDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.chapters = AudioPlayer.shared.chapters
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.bufferingDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.buffering = AudioPlayer.shared.buffering
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.routeDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.isUsingExternalRoute = AudioPlayer.shared.isUsingExternalRoute
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.timeDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.chapterDuration = AudioPlayer.shared.chapterDuration
                self?.chapterCurrentTime = AudioPlayer.shared.chapterCurrentTime
                
                self?.itemDuration = AudioPlayer.shared.itemDuration
                self?.itemCurrentTime = AudioPlayer.shared.itemCurrentTime
                
                if let expiresAt = SleepTimer.shared.expiresAt {
                    self?.remainingSleepTime = DispatchTime.now().distance(to: expiresAt).timeInterval
                } else {
                    self?.remainingSleepTime = nil
                }
                
                self?.sleepTimerExpiresAtChapterEnd = SleepTimer.shared.expiresAtChapterEnd
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.speedDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation {
                    self?.playbackRate = AudioPlayer.shared.playbackRate
                }
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.queueDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                withAnimation {
                    self?.queue = AudioPlayer.shared.queue
                }
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.backwardsNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.notifyBackwards += 1
            }
        })
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.forwardsNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.notifyForwards += 1
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: OfflineManager.bookmarksUpdatedNotification, object: nil, queue: nil) { [weak self] _ in
            Task {
                await self?.updateBookmarks()
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: UIWindow.deviceDidShakeNotification, object: nil, queue: nil) { _ in
            guard Defaults[.shakeExtendsSleepTimer] else {
                return
            }
            
            SleepTimer.shared.extend()
        })
        
        Task {
            for await skipForwardsInterval in Defaults.updates(.skipForwardsInterval) {
                await MainActor.withAnimation {
                    self.skipForwardsInterval = skipForwardsInterval
                }
            }
            for await skipBackwardsInterval in Defaults.updates(.skipBackwardsInterval) {
                await MainActor.withAnimation {
                    self.skipBackwardsInterval = skipBackwardsInterval
                }
            }
        }
    }
    
    func updateBookmarks() async {
        if let item = await item, item.type == .audiobook, let bookmarks = try? OfflineManager.shared.bookmarks(itemId: item.identifiers.itemID) {
            await MainActor.withAnimation {
                self.bookmarks = bookmarks
                self.bookmarkEditingIndex = nil
            }
        } else {
            await MainActor.withAnimation {
                self.bookmarks = []
                self.bookmarkEditingIndex = nil
            }
        }
    }
}

internal extension NowPlaying.ViewModel {
    func setPosition(percentage: Double) {
        Task { @MainActor in
            draggedPercentage = percentage
        }
        
        AudioPlayer.shared.chapterCurrentTime = AudioPlayer.shared.chapterDuration * percentage
    }
    
    func dismissBookmarkAlert() {
        Task { @MainActor in
            bookmarkCapturedTime = nil
        }
    }
    func presentBookmarkAlert() {
        Task { @MainActor in
            guard item?.type == .audiobook else {
                return
            }
            
            bookmarkCapturedTime = AudioPlayer.shared.itemCurrentTime
        }
    }
    
    func createBookmark() {
        Task {
            guard let item = await item, item.type == .audiobook else {
                return
            }
            
            do {
                try await OfflineManager.shared.createBookmark(itemId: item.id, position: AudioPlayer.shared.itemCurrentTime, note: Date.now.formatted(date: .complete, time: .shortened))
                
                await MainActor.run {
                    notifyBookmark += 1
                }
            } catch {
                await MainActor.run {
                    notifyError += 1
                }
            }
            
            await updateBookmarks()
        }
    }
    func createBookmarkWithNote() {
        Task {
            guard let item = await item, let bookmarkCapturedTime = await bookmarkCapturedTime, item.type == .audiobook else {
                return
            }
            
            do {
                try await OfflineManager.shared.createBookmark(itemId: item.identifiers.itemID, position: bookmarkCapturedTime, note: bookmarkNote)
                
                await MainActor.run {
                    notifyBookmark += 1
                }
            } catch {
                await MainActor.run {
                    notifyError += 1
                }
            }
            
            await MainActor.run {
                self.bookmarkCapturedTime = nil
            }
            
            await updateBookmarks()
        }
    }
    
    func updateBookmark(note: String) {
        Task {
            guard let item = await item, let index = await bookmarkEditingIndex, item.type == .audiobook else {
                return
            }
            
            do {
                try await OfflineManager.shared.updateBookmark(itemId: item.identifiers.itemID, position: bookmarks[index].position, note: note)
                
                await MainActor.run {
                    notifyBookmark += 1
                }
            } catch {
                await MainActor.run {
                    notifyError += 1
                }
            }
            
            await MainActor.run {
                self.sheetPresented = true
                self.bookmarkEditingIndex = nil
            }
            
            await updateBookmarks()
        }
    }
    
    func deleteBookmark(index: Int) {
        Task {
            do {
                try await OfflineManager.shared.deleteBookmark(bookmarks[index])
                
                await MainActor.run {
                    notifyBookmark += 1
                }
            } catch {
                await MainActor.run {
                    notifyError += 1
                }
            }
        }
    }
}

internal extension NowPlaying.ViewModel {
    enum SheetTab: Identifiable, Hashable, Equatable, CaseIterable {
        case queue
        case chapters
        case bookmarks
        
        var id: Self {
            self
        }
        
        var label: LocalizedStringKey {
            switch self {
            case .queue:
                "nowPlaying.sheet.queue"
            case .chapters:
                "nowPlaying.sheet.chapters"
            case .bookmarks:
                "nowPlaying.sheet.bookmarks"
            }
        }
        var icon: String {
            switch self {
            case .queue:
                "number"
            case .chapters:
                "book.pages"
            case .bookmarks:
                "star.fill"
            }
        }
        
        var next: Self {
            switch self {
            case .queue:
                    .chapters
            case .chapters:
                    .bookmarks
            case .bookmarks:
                    .queue
            }
        }
    }
}
