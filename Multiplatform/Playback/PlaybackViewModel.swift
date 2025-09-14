//
//  PlaybackState.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class PlaybackViewModel {
    // Pill position
    
    var pillX: CGFloat = .zero
    var pillY: CGFloat = .zero
    
    var pillWidth: CGFloat = .zero
    var pillHeight: CGFloat = .zero
    
    // Image position
    
    var pillImageX: CGFloat = .zero
    var pillImageY: CGFloat = .zero
    var pillImageSize: CGFloat = .zero
    
    var expandedImageX: CGFloat = .zero
    var expandedImageY: CGFloat = .zero
    var expandedImageSize: CGFloat = .zero
    
    let PILL_IMAGE_CORNER_RADIUS: CGFloat = 8
    let EXPANDED_IMAGE_CORNER_RADIUS: CGFloat = 28
    
    // Drag
    
    var translationY: CGFloat = .zero
    
    // Expansion
    
    private(set) var isExpanded = false
    private(set) var isNowPlayingBackgroundVisible = false
    
    private(set) var expansionAnimationCount = 0
    var translateYAnimationCount = 0
    
    var isQueueVisible = false
    
    // Bookmark
    
    var isCreateBookmarkAlertVisible = false
    var isCreatingBookmark = false
    
    var bookmarkNote = ""
    var bookmarkCapturedTime: UInt64?
    
    // Sliders
    
    var seeking: Percentage?
    var seekingTotal: Percentage?
    var volumePreview: Percentage?
    
    @ObservableDefault(.skipBackwardsInterval) @ObservationIgnored
    private(set) var skipBackwardsInterval: Int
    @ObservableDefault(.skipForwardsInterval) @ObservationIgnored
    private(set) var skipForwardsInterval: Int
    
    private(set) var authorIDs = [(ItemIdentifier, String)]()
    private(set) var narratorIDs = [(ItemIdentifier, String)]()
    private(set) var seriesIDs = [(ItemIdentifier, String)]()
    
    private var stoppedPlayingAt: Date?
    
    private(set) var keyboardsVisible = 0
    
    private(set) var notifyError = false
    private(set) var notifySuccess = false
    
    private init() {
        RFNotification[.playbackItemChanged].subscribe { [weak self] (itemID, _, _) in
            if let stoppedPlayingAt = self?.stoppedPlayingAt {
                let distance = stoppedPlayingAt.distance(to: .now)
                
                if distance > 3 {
                    self?.isExpanded = true
                }
            } else {
                self?.isExpanded = true
            }
            
            self?.loadIDs(itemID: itemID)
        }
        RFNotification[.playbackStopped].subscribe { [weak self] in
            self?.isExpanded = false
            self?.translationY = 0
            
            self?.expansionAnimationCount = 0
            self?.keyboardsVisible = 0
            
            self?.isCreateBookmarkAlertVisible = false
            self?.isCreatingBookmark = false
            
            self?.authorIDs = []
            self?.narratorIDs = []
            self?.seriesIDs = []
            
            self?.stoppedPlayingAt = .now
        }
        
        RFNotification[.navigate].subscribe { [weak self] _ in
            self?.isExpanded = false
        }
        
        RFNotification.NonIsolatedNotification<RFNotificationEmptyPayload>(UIResponder.keyboardWillShowNotification.rawValue).subscribe { [weak self] in
            self?.keyboardsVisible += 1
        }
        RFNotification.NonIsolatedNotification<RFNotificationEmptyPayload>(UIResponder.keyboardWillHideNotification.rawValue).subscribe { [weak self] in
            self?.keyboardsVisible -= 1
        }
        
        RFNotification[.scenePhaseDidChange].subscribe { [weak self] _ in
            self?.keyboardsVisible = 0
        }
    }
    
    var areSlidersInUse: Bool {
        seeking != nil || seekingTotal != nil || volumePreview != nil
    }
    
    var nowPlayingMirrorCornerRadius: CGFloat {
        guard isExpanded else {
            return 100
        }
        
        if expansionAnimationCount > 0 || translationY > 0 || translateYAnimationCount > 0 {
            return UIScreen.main.displayCornerRadius
        }
        
        return 0
    }
    
    func toggleExpanded() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Foreground, background removal
        // let ANIMATION_TIMING = (5.0, 4.0)
        let ANIMATION_TIMING = (0.4, 0.32)
        
        if isNowPlayingBackgroundVisible {
            expansionAnimationCount += 1
            
            withAnimation(.easeIn(duration: ANIMATION_TIMING.1)) {
                isNowPlayingBackgroundVisible = false
            }
            
            withAnimation(.spring(duration: ANIMATION_TIMING.0, bounce: 0.12)) {
                isExpanded = false
            } completion: {
                self.translationY = 0
                self.expansionAnimationCount -= 1
            }
        } else {
            translationY = 0
            expansionAnimationCount += 1
            isNowPlayingBackgroundVisible = true
            
            withAnimation(.spring(duration: ANIMATION_TIMING.0, bounce: 0.36)) {
                isExpanded = true
            } completion: {
                self.expansionAnimationCount -= 1
            }
        }
    }
    
    nonisolated func createQuickBookmark() {
        Task {
            await MainActor.withAnimation {
                isCreatingBookmark = true
            }
            
            do {
                try await AudioPlayer.shared.createQuickBookmark()
                let _ = try? await CreateBookmarkIntent().donate()
                
                await MainActor.withAnimation {
                    notifySuccess.toggle()
                    isCreatingBookmark = false
                }
            } catch {
                await MainActor.withAnimation {
                    notifyError.toggle()
                    isCreatingBookmark = false
                }
            }
        }
    }
    nonisolated func cyclePlaybackSpeed() {
        Task {
            await AudioPlayer.shared.cyclePlaybackSpeed()
            await MainActor.run {
                notifySuccess.toggle()
            }
        }
    }
    
    func presentCreateBookmarkAlert() {
        Task {
            guard let currentTime = await AudioPlayer.shared.currentTime else {
                return
            }
            
            bookmarkNote = ""
            bookmarkCapturedTime = UInt64(currentTime)
            isCreateBookmarkAlertVisible = true
        }
    }
    func cancelBookmarkCreation() {
        isCreatingBookmark = false
        isCreateBookmarkAlertVisible = false
        
        bookmarkNote = ""
        self.bookmarkCapturedTime = nil
    }
    nonisolated func finalizeBookmarkCreation() {
        Task {
            guard let bookmarkCapturedTime = await bookmarkCapturedTime, let currentItemID = await AudioPlayer.shared.currentItemID else {
                return
            }
            
            let note = await bookmarkNote.trimmingCharacters(in: .whitespacesAndNewlines)
            
            await MainActor.withAnimation {
                isCreatingBookmark = true
            }
            
            do {
                if note.isEmpty {
                    try await AudioPlayer.shared.createQuickBookmark()
                } else {
                    try await PersistenceManager.shared.bookmark.create(at: bookmarkCapturedTime, note: await bookmarkNote, for: currentItemID)
                }
            
                await MainActor.run {
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
            
            await MainActor.withAnimation {
                isCreatingBookmark = false
                isCreateBookmarkAlertVisible = false
                
                bookmarkNote = ""
                self.bookmarkCapturedTime = nil
            }
        }
    }
}

private extension PlaybackViewModel {
    nonisolated func loadIDs(itemID: ItemIdentifier) {
        Task {
            guard let item = try? await itemID.resolved else {
                return
            }
            
            await withTaskGroup {
                $0.addTask { await self.loadAuthorIDs(item: item) }
                $0.addTask { await self.loadNarratorIDs(item: item) }
                $0.addTask { await self.loadSeriesIDs(item: item) }
            }
        }
    }
    nonisolated func loadAuthorIDs(item: Item) async {
        var authorIDs = [(ItemIdentifier, String)]()
        
        for author in item.authors {
            do {
                let authorID = try await ABSClient[item.id.connectionID].authorID(from: item.id.libraryID, name: author)
                authorIDs.append((authorID, author))
            } catch {}
        }
        
        await MainActor.withAnimation {
            self.authorIDs = authorIDs
        }
    }
    nonisolated func loadNarratorIDs(item: Item) async {
        guard let audiobook = item as? Audiobook else {
            await MainActor.withAnimation {
                self.narratorIDs.removeAll()
            }
            
            return
        }
        
        let mapped = audiobook.narrators.map { (Person.convertNarratorToID($0, libraryID: item.id.libraryID, connectionID: item.id.connectionID), $0) }
        
        await MainActor.withAnimation {
            self.narratorIDs = mapped
        }
    }
    nonisolated func loadSeriesIDs(item: Item) async {
        guard let audiobook = item as? Audiobook else {
            await MainActor.withAnimation {
                self.seriesIDs.removeAll()
            }
            
            return
        }
        
        var seriesIDs = [(ItemIdentifier, String)]()
        
        for series in audiobook.series {
            if let seriesID = series.id {
                seriesIDs.append((seriesID, series.name))
                continue
            }
            
            do {
                let seriesID = try await ABSClient[item.id.connectionID].seriesID(from: item.id.libraryID, name: series.name)
                seriesIDs.append((seriesID, series.name))
            } catch {
                continue
            }
        }
        
        await MainActor.withAnimation {
            self.seriesIDs = seriesIDs
        }
    }
}

extension PlaybackViewModel {
    static let shared = PlaybackViewModel()
}
