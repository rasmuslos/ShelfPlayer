//
//  Satellite.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.01.25.
//

import SwiftUI
import Defaults
import DefaultsMacros
import RFNotifications
import ShelfPlayerKit
import SPPlayback

@Observable @MainActor
final class Satellite {
    // MARK: Navigation
    
    var isOffline: Bool
    
    @ObservableDefault(.lastTabValue) @ObservationIgnored
    var lastTabValue: TabValue?
    
    // MARK: Playback
    
    private(set) var item: PlayableItem?
    private(set) var playing: Bool
    
    private(set) var currentTime: TimeInterval
    private(set) var currentChapterTime: TimeInterval
    
    private(set) var duration: TimeInterval
    private(set) var chapterDuration: TimeInterval
    
    // MARK: Playback helper
    
    private(set) var loading: Int
    
    // MARK: Utility
    
    private(set) var notifyError: Bool
    private(set) var notifySuccess: Bool
    
    private var stash: RFNotification.MarkerStash
    
    init() {
        isOffline = false
        
        item = nil
        playing = false
        
        currentTime = 0
        currentChapterTime = 0
        
        duration = 0
        chapterDuration = 0
        
        loading = 0
        
        notifyError = false
        notifySuccess = false
        
        stash = .init()
        setupObservers()
    }
}

extension Satellite {
    var isLoading: Bool {
        loading > 0
    }
    
    nonisolated func play(_ item: PlayableItem) {
        Task {
            guard await self.item != item else {
                // TODO: PAUSE
                return
            }
            
            await MainActor.withAnimation {
                loading += 1
            }
            
            do {
                try await AudioPlayer.shared.start(item.id)
                
                await MainActor.run {
                    loading -= 1
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    loading -= 1
                    notifyError.toggle()
                }
            }
        }
    }
    
    nonisolated func queue(_ item: PlayableItem) {
        Task {
            await MainActor.withAnimation {
                loading += 1
            }
            
            do {
                // try await AudioPlayer.shared.queue([.init(itemID: item.id, startWithoutListeningSession: <#T##Bool#>, origin: <#T##QueueItem.QueueItemOrigin#>)])
                
                await MainActor.run {
                    loading -= 1
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.withAnimation {
                    loading -= 1
                    notifyError.toggle()
                }
            }
        }
    }
    
    nonisolated func deleteProgress(_ item: PlayableItem) {
        Task {
            await MainActor.withAnimation {
                loading += 1
            }
            
            do {
                try await PersistenceManager.shared.progress.delete(itemID: item.id)
                
                await MainActor.run {
                    loading -= 1
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    loading -= 1
                    notifyError.toggle()
                }
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
