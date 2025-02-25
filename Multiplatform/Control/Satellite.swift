//
//  Satellite.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.01.25.
//

import SwiftUI
import OSLog
import Defaults
import DefaultsMacros
import ShelfPlayerKit
import SPPlayback

@Observable @MainActor
final class Satellite {
    let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "Satellite")
    
    // MARK: Navigation
    
    var isOffline: Bool
    
    @ObservableDefault(.lastTabValue) @ObservationIgnored
    var lastTabValue: TabValue?
    
    // MARK: Playback
    
    private(set) var currentItem: PlayableItem?
    
    private(set) var isPlaying: Bool
    private(set) var isBuffering: Bool
    
    private(set) var currentTime: TimeInterval
    private(set) var currentChapterTime: TimeInterval
    
    private(set) var duration: TimeInterval
    private(set) var chapterDuration: TimeInterval
    
    // MARK: Playback helper
    
    private(set) var totalLoading: Int
    private(set) var busy: [ItemIdentifier: Int]
    
    // MARK: Utility
    
    private(set) var notifyError: Bool
    private(set) var notifySuccess: Bool
    
    private var stash: RFNotification.MarkerStash
    
    init() {
        isOffline = false
        
        currentItem = Audiobook.fixture
        
        isPlaying = false
        isBuffering = true
        
        currentTime = 0
        currentChapterTime = 0
        
        duration = 0
        chapterDuration = 0
        
        totalLoading = 0
        busy = [:]
        
        notifyError = false
        notifySuccess = false
        
        stash = .init()
        setupObservers()
    }
    
    private func startWorking(on itemID: ItemIdentifier) {
        withAnimation {
            let current = busy[itemID]
            
            if current == nil {
                busy[itemID] = 1
            } else {
                busy[itemID]! += 1
            }
        }
    }
    private func endWorking(on itemID: ItemIdentifier, successfully: Bool?) {
        withAnimation {
            guard let current = busy[itemID] else {
                logger.warning("Ending work on \(itemID) but no longer busy")
                return
            }
            
            busy[itemID] = current - 1
            
            if let successfully {
                if successfully {
                    notifySuccess.toggle()
                } else {
                    notifyError.toggle()
                }
            }
        }
    }
}

extension Satellite {
    func isLoading(observing: ItemIdentifier) -> Bool {
        totalLoading > 0 || busy[observing] ?? 0 > 0
    }
    
    nonisolated func play() {
    }
    nonisolated func pause() {
    }
    
    nonisolated func start(_ item: PlayableItem) {
        Task {
            guard await self.currentItem != item else {
                // TODO: PAUSE
                return
            }
            
            await startWorking(on: item.id)
            
            do {
                try await AudioPlayer.shared.start(item.id)
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
    
    nonisolated func queue(_ item: PlayableItem) {
        Task {
            await startWorking(on: item.id)
            
            do {
                // try await AudioPlayer.shared.queue([.init(itemID: item.id, startWithoutListeningSession: <#T##Bool#>, origin: <#T##QueueItem.QueueItemOrigin#>)])
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
    
    nonisolated func markAsFinished(_ item: PlayableItem) {
        Task {
            await startWorking(on: item.id)
            
            do {
                try await PersistenceManager.shared.progress.markAsCompleted(item.id)
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
    nonisolated func markAsUnfinished(_ item: PlayableItem) {
        Task {
            await startWorking(on: item.id)
            
            do {
                try await PersistenceManager.shared.progress.markAsListening(item.id)
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
    nonisolated func deleteProgress(_ item: PlayableItem) {
        Task {
            await startWorking(on: item.id)
            
            do {
                try await PersistenceManager.shared.progress.delete(itemID: item.id)
                await endWorking(on: item.id, successfully: true)
            } catch {
                await endWorking(on: item.id, successfully: false)
            }
        }
    }
}

private extension Satellite {
    private func setupObservers() {
        RFNotification[.changeOfflineMode].subscribe { [weak self] in
            self?.isOffline = $0
        }.store(in: &stash)
    }
}
