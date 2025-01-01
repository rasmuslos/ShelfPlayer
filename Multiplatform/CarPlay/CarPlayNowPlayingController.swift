//
//  CarPlayNowPlayingController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

internal class CarPlayNowPlayingController: NSObject {
    private let template = CPNowPlayingTemplate.shared
    private let interfaceController: CPInterfaceController
    
    private let queueController: CarPlayQueueController
    
    private let rateButton: CPNowPlayingPlaybackRateButton
    private let nextButton: CPNowPlayingImageButton
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        queueController = .init(interfaceController: interfaceController)
        
        rateButton = CPNowPlayingPlaybackRateButton { _ in
            var rate = AudioPlayer.shared.playbackRate + Defaults[.playbackSpeedAdjustment]
            
            if rate > 2 {
                rate = 0.25
            }
            
            AudioPlayer.shared.playbackRate = rate
        }
        nextButton = CPNowPlayingImageButton(image: .init(systemName: "forward.end.fill")!) { _ in
            Task {
                try await AudioPlayer.shared.advance(to: 0)
            }
        }
        
        super.init()
        
        setupObservers()
        update()
    }
    deinit {
        template.remove(self)
    }
}

extension CarPlayNowPlayingController: CPNowPlayingTemplateObserver {
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        Task {
            // try await interfaceController.pushTemplate(queueController.template, animated: true)
        }
    }
    func nowPlayingTemplateAlbumArtistButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
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
    }
}

private extension CarPlayNowPlayingController {
    func update() {
        if AudioPlayer.shared.queue.isEmpty {
            template.updateNowPlayingButtons([rateButton])
        } else {
            template.updateNowPlayingButtons([rateButton, nextButton])
        }
        
        template.isUpNextButtonEnabled = true
        template.isAlbumArtistButtonEnabled = true
    }
    
    func setupObservers() {
        template.add(self)
        
        NotificationCenter.default.addObserver(forName: AudioPlayer.queueDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.update()
        }
    }
}
