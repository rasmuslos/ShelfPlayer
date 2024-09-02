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
        
        // MARK: Chapter
        
        @MainActor var bookmarkNote: String
        @MainActor var bookmarkCapturedTime: TimeInterval?
        
        // MARK: Helper
        
        @MainActor private(set) var notifyPlaying: Int
        @MainActor private(set) var notifyBookmark: Int
        
        @MainActor private(set) var notifyForwards: Int
        @MainActor private(set) var notifyBackwards: Int
        
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
            
            bookmarkNote = ""
            bookmarkCapturedTime = nil
            
            notifyPlaying = 0
            notifyBookmark = 0
            
            notifyForwards = 0
            notifyBackwards = 0
            
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
                    
                    if item == nil && self?.item != nil {
                        self?.expanded = true
                    } else if self?.item == nil {
                        self?.expanded = false
                    }
                }
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
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.bufferingDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.buffering = AudioPlayer.shared.buffering
            }
        })
        
        tokens.append(NotificationCenter.default.addObserver(forName: AudioPlayer.timeDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.chapterDuration = AudioPlayer.shared.chapterDuration
                self?.chapterCurrentTime = AudioPlayer.shared.chapterCurrentTime
                
                self?.itemDuration = AudioPlayer.shared.itemDuration
                self?.itemCurrentTime = AudioPlayer.shared.itemCurrentTime
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
        
        Task {
            for await skipForwardsInterval in Defaults.updates(.skipForwardsInterval) {
                await MainActor.run {
                    self.skipForwardsInterval = skipForwardsInterval
                }
            }
            for await skipBackwardsInterval in Defaults.updates(.skipBackwardsInterval) {
                await MainActor.run {
                    self.skipBackwardsInterval = skipBackwardsInterval
                }
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
            bookmarkCapturedTime = AudioPlayer.shared.itemCurrentTime
        }
    }
    
    func createBookmark() {
        Task {
            guard let item = await item else {
                return
            }
            
            await OfflineManager.shared.createBookmark(itemId: item.id, position: AudioPlayer.shared.itemCurrentTime, note: Date.now.formatted(date: .complete, time: .shortened))
            await MainActor.run {
                notifyBookmark += 1
            }
        }
    }
    func createBookmarkWithNote() {
        Task {
            guard let item = await item, let bookmarkCapturedTime = await bookmarkCapturedTime else {
                return
            }
            
            await OfflineManager.shared.createBookmark(itemId: item.identifiers.itemID, position: bookmarkCapturedTime, note: bookmarkNote)
            
            await MainActor.run {
                self.bookmarkCapturedTime = nil
                notifyBookmark += 1
            }
        }
    }
}
