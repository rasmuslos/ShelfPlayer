//
//  CarPlayNowPlayingController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
@preconcurrency import CarPlay
import ShelfPlayback

@MainActor
class CarPlayNowPlayingController: NSObject {
    private let template = CPNowPlayingTemplate.shared
    private let interfaceController: CPInterfaceController
    
    private let queueController: CarPlayQueueController
    private let chaptersController: CarPlayChaptersController
    
    private let rateButton: CPNowPlayingPlaybackRateButton
    private let nextButton: CPNowPlayingImageButton
    private let bookmarkButton: CPNowPlayingImageButton
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        queueController = .init(interfaceController: interfaceController)
        chaptersController = .init(interfaceController: interfaceController)
        
        rateButton = CPNowPlayingPlaybackRateButton { _ in
            Task {
                await AudioPlayer.shared.cyclePlaybackSpeed()
            }
        }
        nextButton = CPNowPlayingImageButton(image: UIImage(systemName: "forward.end.fill")!) { _ in
            Task {
                await AudioPlayer.shared.advance()
            }
        }
        bookmarkButton = CPNowPlayingImageButton(image: UIImage(systemName: "bookmark.fill")!) { _ in
            Task {
                try await AudioPlayer.shared.createQuickBookmark()
            }
        }
        
        super.init()
        
        template.isAlbumArtistButtonEnabled = true
        
        template.add(self)
        
        RFNotification[.queueChanged].subscribe { [weak self] _ in
            self?.update()
            self?.queueController.update()
        }
        RFNotification[.upNextQueueChanged].subscribe { [weak self] _ in
            self?.update()
            self?.queueController.update()
        }
        RFNotification[.playbackItemChanged].subscribe { [weak self] _ in
            self?.update()
        }
        
        update()
    }
    deinit {
        template.remove(self)
    }
    
    func update() {
        Task {
            let queue = await AudioPlayer.shared.queue
            let upNextQueue = await AudioPlayer.shared.upNextQueue
            let currentItemID = await AudioPlayer.shared.currentItemID
            
            let isQueueEmpty = queue.isEmpty && upNextQueue.isEmpty
            var buttons = [CPNowPlayingButton]([rateButton])
            
            if currentItemID?.type == .audiobook {
                buttons.append(bookmarkButton)
            }
            
            if !isQueueEmpty {
                buttons.append(nextButton)
            }
            
            template.updateNowPlayingButtons(buttons)
            template.isAlbumArtistButtonEnabled = true
            template.isUpNextButtonEnabled = !isQueueEmpty
        }
    }
    private func applyQueueToNextUpButton() {
        template.upNextTitle = String(localized: "playback.queue")
        template.isUpNextButtonEnabled = true
    }
}

extension CarPlayNowPlayingController: @preconcurrency CPNowPlayingTemplateObserver {
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        Task {
            try await interfaceController.pushTemplate(queueController.template, animated: true)
        }
    }
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        Task {
            guard let currentItemID = await AudioPlayer.shared.currentItemID else {
                return
            }
            
            if currentItemID.type == .audiobook {
                try await interfaceController.pushTemplate(chaptersController.template, animated: true)
            } else if currentItemID.type == .episode {
                let podcastID = ItemIdentifier(primaryID: currentItemID.groupingID!, groupingID: nil, libraryID: currentItemID.libraryID, connectionID: currentItemID.connectionID, type: .podcast)
                
                guard let podcast = try await podcastID.resolved as? Podcast else {
                    return
                }
                
                let controller = CarPlayPodcastController(interfaceController: interfaceController, podcast: podcast)
                try await interfaceController.pushTemplate(controller.template, animated: true)
            }
        }
    }
}
