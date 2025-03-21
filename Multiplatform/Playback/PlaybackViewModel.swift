//
//  PlaybackState.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI
import Defaults
import DefaultsMacros
import ShelfPlayerKit
import SPPlayback

@Observable @MainActor
final class PlaybackViewModel {
    private var _isExpanded: Bool
    private var _dragOffset: CGFloat
    
    var isQueueVisible: Bool
    var isCreateBookmookAlertVisible: Bool
    var isCreatingBookmark: Bool
    
    var bookmarkNote: String
    var bookmarkCapturedTime: UInt64?
    
    var seeking: Percentage?
    var seekingTotal: Percentage?
    var volumePreview: Percentage?
    
    @ObservableDefault(.skipBackwardsInterval) @ObservationIgnored
    private(set) var skipBackwardsInterval: Int
    @ObservableDefault(.skipForwardsInterval) @ObservationIgnored
    private(set) var skipForwardsInterval: Int
    
    private(set) var seriesIDs: [(ItemIdentifier, String)]
    private(set) var authorIDs: [(ItemIdentifier, String)]
    
    private var stoppedPlayingAt: Date?
    
    private(set) var notifySkipBackwards = false
    private(set) var notifySkipForwards = false
    
    private(set) var notifyError = false
    private(set) var notifySuccess = false
    
    init() {
        _dragOffset = .zero
        _isExpanded = false
        
        bookmarkNote = ""
        
        isQueueVisible = false
        isCreateBookmookAlertVisible = false
        isCreatingBookmark = false
        
        seriesIDs = []
        authorIDs = []
        
        RFNotification[.skipped].subscribe { [weak self] forwards in
            if forwards {
                self?.notifySkipForwards.toggle()
            } else {
                self?.notifySkipBackwards.toggle()
            }
        }
        
        RFNotification[.playbackItemChanged].subscribe { [weak self] (itemID, _, _) in
            if let stoppedPlayingAt = self?.stoppedPlayingAt {
                let distance = stoppedPlayingAt.distance(to: .now)
                
                if distance > 3 {
                    self?.isExpanded = true
                }
            } else {
                self?.isExpanded = true
            }
            
            self?.loadAuthorIDs(itemID: itemID)
        }
        RFNotification[.playbackStopped].subscribe { [weak self] in
            self?.isExpanded = false
            self?.dragOffset = 0
            
            self?.authorIDs = []
            
            self?.stoppedPlayingAt = .now
        }
        
        RFNotification[.navigateNotification].subscribe { [weak self] _ in
            self?.isExpanded = false
        }
    }
    
    var isExpanded: Bool {
        get {
            _isExpanded
        }
        set {
            _isExpanded = newValue
            
            if newValue {
                _dragOffset = 0
            } else if _dragOffset == 0 {
                // this is stupid
                // this will trigger an view update
                // because the scaleEffect depends on this variable
                // and we need the NavigationStack to update
                // so it will not do so after the animation finishes, causing a ugly mess
                // if the user is dragging this already happens, so we trigger an update only when
                // the user isn't dragging (dragOffset == 0) by setting it to the same value (0)
                // If you are reading this, hire me
                _dragOffset = 0
            }
        }
    }
    
    var dragOffset: CGFloat {
        get {
            if isExpanded {
                return _dragOffset
            }
            
            return 0
        }
        set {
            _dragOffset = max(0, min(newValue, 2000))
        }
    }
    var pushAmount: Percentage {
        // technically a CGFloat
        let dragHeight: Percentage = 500
        
        if dragOffset > 0 {
            return 1 - (1 - min(dragHeight, max(0, dragOffset)) / dragHeight) * 0.15
        }
        
        return isExpanded ? 0.85 : 1
    }
    
    var areSlidersInUse: Bool {
        seeking != nil || seekingTotal != nil || volumePreview != nil
    }
    
    var backgroundCornerRadius: CGFloat {
        if isExpanded {
            UIScreen.main.displayCornerRadius
        } else {
            16
        }
    }
    func pushContainerCornerRadius(leadingOffset: CGFloat) -> CGFloat {
        max(8, UIScreen.main.displayCornerRadius - leadingOffset)
    }
    
    func presentCreateBookmarkAlert() {
        Task {
            guard let currentTime = await AudioPlayer.shared.currentTime else {
                return
            }
            
            bookmarkNote = ""
            bookmarkCapturedTime = UInt64(currentTime)
            isCreateBookmookAlertVisible = true
        }
    }
    func cancalBookmarkCreation() {
        isCreatingBookmark = false
        isCreateBookmookAlertVisible = false
        
        bookmarkNote = ""
        self.bookmarkCapturedTime = nil
    }
    nonisolated func finalizeBookmarkCreation() {
        Task {
            guard let bookmarkCapturedTime = await bookmarkCapturedTime, let currentItemID = await AudioPlayer.shared.currentItemID else {
                return
            }
            
            let note = await bookmarkNote.trimmingCharacters(in: .whitespacesAndNewlines)
            
            guard !note.isEmpty else {
                await MainActor.run {
                    notifyError.toggle()
                }
                
                return
            }
            
            await MainActor.withAnimation {
                isCreatingBookmark = true
            }
            
            do {
                try await PersistenceManager.shared.bookmark.create(at: bookmarkCapturedTime, note: await bookmarkNote, for: currentItemID)
            
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
                isCreateBookmookAlertVisible = false
                
                bookmarkNote = ""
                self.bookmarkCapturedTime = nil
            }
        }
    }
}

private extension PlaybackViewModel {
    func loadAuthorIDs(itemID: ItemIdentifier) {
        Task {
            guard let item = try? await itemID.resolved else {
                return
            }
            
            var authorIDs = [(ItemIdentifier, String)]()
            
            for author in item.authors {
                do {
                    let authorID = try await ABSClient[itemID.connectionID].authorID(from: itemID.libraryID, name: author)
                    authorIDs.append((authorID, author))
                } catch {}
            }
            
            await MainActor.withAnimation {
                self.authorIDs = authorIDs
            }
        }
    }
}
