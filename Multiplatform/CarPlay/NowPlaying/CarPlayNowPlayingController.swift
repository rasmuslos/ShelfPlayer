//
//  CarPlayNowPlayingController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//
import Foundation
@preconcurrency import CarPlay
import ShelfPlayback

final class CarPlayNowPlayingController: NSObject {
    private let template = CPNowPlayingTemplate.shared
    
    private let interfaceController: CPInterfaceController
    private let queueController: CarPlayQueueController
    private let chaptersController: CarPlayChaptersController
    
    private let rateButton: CPNowPlayingPlaybackRateButton
    private let advanceQueueButton: CPNowPlayingImageButton
    private let bookmarkButton: CPNowPlayingImageButton
    private let nextChapterButton: CPNowPlayingImageButton
    
    private var updateTask: Task<Void, Never>?
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        queueController = CarPlayQueueController()
        chaptersController = CarPlayChaptersController()
        
        rateButton = CPNowPlayingPlaybackRateButton { _ in
            Task {
                await AudioPlayer.shared.cyclePlaybackSpeed()
            }
        }
        
        advanceQueueButton = CPNowPlayingImageButton(image: UIImage(systemName: "forward.end.fill") ?? UIImage()) { _ in
            Task {
                await AudioPlayer.shared.advance()
            }
        }
        
        bookmarkButton = CPNowPlayingImageButton(image: UIImage(systemName: "bookmark.fill") ?? UIImage()) { _ in
            Task {
                try? await AudioPlayer.shared.createQuickBookmark()
            }
        }
        
        nextChapterButton = CPNowPlayingImageButton(image: UIImage(systemName: "forward.frame.fill") ?? UIImage()) { _ in
            Task {
                await Self.skipToNextChapter()
            }
        }
        
        super.init()
        
        template.isAlbumArtistButtonEnabled = true
        template.add(self)
        
        RFNotification[.queueChanged].subscribe { [weak self] _ in
            self?.queueController.update()
            self?.update()
        }
        RFNotification[.upNextQueueChanged].subscribe { [weak self] _ in
            self?.queueController.update()
            self?.update()
        }
        RFNotification[.playbackItemChanged].subscribe { [weak self] _ in
            self?.update()
        }
        RFNotification[.chapterChanged].subscribe { [weak self] _ in
            self?.update()
        }
        
        update()
    }
    
    deinit {
        updateTask?.cancel()
    }
    
    func remove() {
        template.remove(self)
    }
    
    func update() {
        updateTask?.cancel()
        
        updateTask = Task { [weak self] in
            guard let self else {
                return
            }
            
            let currentItemID = await AudioPlayer.shared.currentItemID
            let queue = await AudioPlayer.shared.queue
            let upNextQueue = await AudioPlayer.shared.upNextQueue
            let activeChapterIndex = await AudioPlayer.shared.activeChapterIndex
            
            let isAudiobook = currentItemID?.type == .audiobook
            let hasQueueAdvance = !queue.isEmpty || !upNextQueue.isEmpty
            
            let hasNextChapter = activeChapterIndex != nil
            
            nextChapterButton.isEnabled = hasNextChapter
            
            var buttons = [CPNowPlayingButton]()
            buttons.append(rateButton)
            
            if isAudiobook {
                buttons.append(bookmarkButton)
            }
            
            if hasNextChapter {
                buttons.append(nextChapterButton)
            }
            
            if hasQueueAdvance {
                buttons.append(advanceQueueButton)
            }
            
            template.updateNowPlayingButtons(Array(buttons.prefix(5)))
            template.isAlbumArtistButtonEnabled = currentItemID != nil
            template.upNextTitle = String(localized: "playback.queue")
            template.isUpNextButtonEnabled = hasQueueAdvance
        }
    }
}

private extension CarPlayNowPlayingController {
    static func skipToNextChapter() async {
        let chapters = await AudioPlayer.shared.chapters
        
        guard let activeChapterIndex = await AudioPlayer.shared.activeChapterIndex else {
            return
        }
        
        let nextIndex = activeChapterIndex + 1
        
        guard chapters.indices.contains(nextIndex) else {
            return
        }
        
        try? await AudioPlayer.shared.seek(to: chapters[nextIndex].startOffset, insideChapter: false)
    }
}

extension CarPlayNowPlayingController: @preconcurrency CPNowPlayingTemplateObserver {
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        Task { [weak self] in
            guard let self else {
                return
            }
            
            _ = try? await interfaceController.pushTemplate(queueController.template, animated: true)
        }
    }
    
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        Task { [weak self] in
            guard let self else {
                return
            }
            
            guard let currentItemID = await AudioPlayer.shared.currentItemID else {
                return
            }
            
            switch currentItemID.type {
                case .audiobook: _ = try? await interfaceController.pushTemplate(chaptersController.template, animated: true)
                default: break
            }
        }
    }
}
