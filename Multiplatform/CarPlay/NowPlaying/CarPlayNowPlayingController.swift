//
//  CarPlayNowPlayingController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

@MainActor
class CarPlayNowPlayingController: NSObject {
    private let template = CPNowPlayingTemplate.shared
    private let interfaceController: CPInterfaceController
    
    private let queueController: CarPlayQueueController
    
    private let rateButton: CPNowPlayingPlaybackRateButton
    private let nextButton: CPNowPlayingImageButton
    private let bookmarkButton: CPNowPlayingImageButton
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        queueController = .init(interfaceController: interfaceController)
        
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
            template.isUpNextButtonEnabled = !isQueueEmpty
        }
    }
}

extension CarPlayNowPlayingController: @preconcurrency CPNowPlayingTemplateObserver {
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        Task {
            try await interfaceController.pushTemplate(queueController.template, animated: true)
        }
    }
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        /*
        if let audiobook = AudioPlayer.shared.item as? Audiobook {
            Task {
                // let controller = CarPlayChaptersController(interfaceController: interfaceController, audiobook: audiobook)
                // try await interfaceController.pushTemplate(controller.template, animated: true)
            }
        } else if let episode = AudioPlayer.shared.item as? Episode {
            Task {
                /*
                let podcast = try await AudiobookshelfClient.shared.podcast(podcastId: episode.podcastId).0
                let controller = CarPlayPodcastController(interfaceController: self.interfaceController, podcast: podcast)
                
                try await self.interfaceController.pushTemplate(controller.template, animated: true)
                 */
            }
        }
         */
    }
}
