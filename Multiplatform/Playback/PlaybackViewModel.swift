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
    
    var isPillBackButtonVisible = true
    var isUsingLegacyPillDesign = false
    
    // Image position
    
    var pillImageX: CGFloat = .zero
    var pillImageY: CGFloat = .zero
    var pillImageSize: CGFloat = .zero
    
    var expandedImageX: CGFloat = .zero
    var expandedImageY: CGFloat = .zero
    var expandedImageSize: CGFloat = .zero
    
    let PILL_IMAGE_CORNER_RADIUS: CGFloat = 8
    let EXPANDED_IMAGE_CORNER_RADIUS: CGFloat = 16
    
    var PILL_CORNER_RADIUS: CGFloat {
        if #available(iOS 26, *) {
            pillHeight
        } else {
            16
        }
    }
    
    // Drag
    
    var translationY: CGFloat = .zero
    var controlTranslationY: CGFloat = .zero
    
    // Expansion
    
    private(set) var isExpanded = false
    private(set) var isRegularExpanded = false
    private(set) var isNowPlayingBackgroundVisible = false
    
    private(set) var nowPlayingShadowVisibleCount = 0
    
    private(set) var showCompactPlaybackBarOnExpandedViewCount = 0
    
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
            guard self?.isExpanded == false else {
                return
            }
            
            self?.loadIDs(itemID: itemID)
            
            Task {
                try? await Task.sleep(for: .seconds(0.2))
                
                if let stoppedPlayingAt = self?.stoppedPlayingAt {
                    let distance = stoppedPlayingAt.distance(to: .now)
                    
                    if distance > 10 {
                        self?.toggleExpanded()
                    }
                } else {
                    self?.toggleExpanded()
                }
            }
        }
        RFNotification[.playbackStopped].subscribe { [weak self] in
            self?.isExpanded = false
            self?.isNowPlayingBackgroundVisible = false
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
            guard self?.isExpanded == true else {
                return
            }
            
            self?.toggleExpanded()
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
    
    func resetAnimationCounts() {
        nowPlayingShadowVisibleCount = 0
        
        expansionAnimationCount = 0
        showCompactPlaybackBarOnExpandedViewCount = 0
    }
    
    func toggleExpanded() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        
        // Foreground, background removal
        // let ANIMATION_TIMING = (5.0, 4.0)
        let ANIMATION_TIMING = (0.36, 0.28)
        
        if isNowPlayingBackgroundVisible {
            expansionAnimationCount += 1
            
            withAnimation(.easeInOut(duration: 0.1)) {
                showCompactPlaybackBarOnExpandedViewCount += 1
            }
            
            withAnimation(.easeOut(duration: 0.3)) {
                nowPlayingShadowVisibleCount = 0
            }
            
            withAnimation(.easeIn(duration: ANIMATION_TIMING.1).delay(0.2)) {
                isNowPlayingBackgroundVisible = false
            }
            
            withAnimation(.easeInOut(duration: ANIMATION_TIMING.0)) {
                isExpanded = false
                controlTranslationY = 400
            } completion: {
                self.expansionAnimationCount -= 1
                self.showCompactPlaybackBarOnExpandedViewCount -= 1
                self.translationY = 0
                
                withAnimation(.smooth.delay(0.2)) {
                    self.controlTranslationY = 0
                }
            }
        } else {
            translationY = 0
            controlTranslationY = 500
            expansionAnimationCount += 1
            isNowPlayingBackgroundVisible = true
            self.showCompactPlaybackBarOnExpandedViewCount += 1
            
            withAnimation(.easeInOut(duration: ANIMATION_TIMING.0)) {
                isExpanded = true
                controlTranslationY = 0
            } completion: {
                self.expansionAnimationCount -= 1
            }
            
            withAnimation(.easeInOut(duration: 0.3)) {
                self.showCompactPlaybackBarOnExpandedViewCount -= 1
            }
            
            withAnimation(.easeIn(duration: 0.3)) {
                nowPlayingShadowVisibleCount += 1
            }
        }
    }
    
    func createQuickBookmark() {
        Task {
            withAnimation {
                isCreatingBookmark = true
            }

            do {
                try await AudioPlayer.shared.createQuickBookmark()
                let _ = try? await CreateBookmarkIntent().donate()

                withAnimation {
                    notifySuccess.toggle()
                    isCreatingBookmark = false
                }
            } catch {
                withAnimation {
                    notifyError.toggle()
                    isCreatingBookmark = false
                }
            }
        }
    }
    func cyclePlaybackSpeed() {
        Task {
            await AudioPlayer.shared.cyclePlaybackSpeed()
            notifySuccess.toggle()
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
    func finalizeBookmarkCreation() {
        Task {
            guard let bookmarkCapturedTime = bookmarkCapturedTime, let currentItemID = await AudioPlayer.shared.currentItemID else {
                return
            }

            let note = bookmarkNote.trimmingCharacters(in: .whitespacesAndNewlines)

            withAnimation {
                isCreatingBookmark = true
            }

            do {
                if note.isEmpty {
                    try await AudioPlayer.shared.createQuickBookmark()
                } else {
                    try await PersistenceManager.shared.bookmark.create(at: bookmarkCapturedTime, note: bookmarkNote, for: currentItemID)
                }

                notifySuccess.toggle()
            } catch {
                notifyError.toggle()
            }

            withAnimation {
                isCreatingBookmark = false
                isCreateBookmarkAlertVisible = false
                
                bookmarkNote = ""
                self.bookmarkCapturedTime = nil
            }
        }
    }
}

private extension PlaybackViewModel {
    func loadIDs(itemID: ItemIdentifier) {
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
    func loadAuthorIDs(item: Item) async {
        var authorIDs = [(ItemIdentifier, String)]()

        for author in item.authors {
            do {
                let authorID = try await ABSClient[item.id.connectionID].authorID(from: item.id.libraryID, name: author)
                authorIDs.append((authorID, author))
            } catch {}
        }

        withAnimation {
            self.authorIDs = authorIDs
        }
    }
    func loadNarratorIDs(item: Item) async {
        guard let audiobook = item as? Audiobook else {
            withAnimation {
                self.narratorIDs.removeAll()
            }

            return
        }

        let mapped = audiobook.narrators.map { (Person.convertNarratorToID($0, libraryID: item.id.libraryID, connectionID: item.id.connectionID), $0) }

        withAnimation {
            self.narratorIDs = mapped
        }
    }
    func loadSeriesIDs(item: Item) async {
        guard let audiobook = item as? Audiobook else {
            withAnimation {
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

        withAnimation {
            self.seriesIDs = seriesIDs
        }
    }
}

extension PlaybackViewModel {
    static let shared = PlaybackViewModel()
}
