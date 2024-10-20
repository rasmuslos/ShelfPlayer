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
    
    private let rateButton: CPNowPlayingPlaybackRateButton
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        rateButton = CPNowPlayingPlaybackRateButton { _ in
            var rate = AudioPlayer.shared.playbackRate + Defaults[.playbackSpeedAdjustment]
            
            if rate > 2 {
                rate = 0.25
            }
            
            AudioPlayer.shared.playbackRate = rate
        }
        
        super.init()
        
        setupObservers()
        update()
    }
}

extension CarPlayNowPlayingController: CPNowPlayingTemplateObserver {
    func nowPlayingTemplateUpNextButtonTapped(_ nowPlayingTemplate: CPNowPlayingTemplate) {
        if let audiobook = AudioPlayer.shared.item as? Audiobook {
            Task {
                let controller = CarPlayChaptersController(interfaceController: interfaceController, audiobook: audiobook)
                try await interfaceController.pushTemplate(controller.template, animated: true)
            }
        } else if let episode = AudioPlayer.shared.item as? Episode {
            Task {
                let podcast = try await AudiobookshelfClient.shared.podcast(podcastId: episode.podcastId).0
                let controller = CarPlayPodcastController(interfaceController: self.interfaceController, podcast: podcast)
                
                try await self.interfaceController.pushTemplate(controller.template, animated: true)
            }
        }
    }
}

private extension CarPlayNowPlayingController {
    var nextButton: CPNowPlayingImageButton {
        .init(image: .init(systemName: "forward.end.fill")!) { _ in
            Task {
                try await AudioPlayer.shared.advance(to: 0)
            }
        }
    }
    
    func setupObservers() {
        template.add(self)
        
        NotificationCenter.default.addObserver(forName: AudioPlayer.itemDidChangeNotification, object: nil, queue: nil) { _ in
            self.update()
        }
        NotificationCenter.default.addObserver(forName: AudioPlayer.queueDidChangeNotification, object: nil, queue: nil) { _ in
            self.update()
        }
    }
    
    private func update() {
        if AudioPlayer.shared.queue.isEmpty {
            template.updateNowPlayingButtons([rateButton])
        } else {
            template.updateNowPlayingButtons([rateButton, nextButton])
        }
        
        guard let item = AudioPlayer.shared.item else {
            template.isAlbumArtistButtonEnabled = false
            template.isUpNextButtonEnabled = false
            
            return
        }
        
        template.isUpNextButtonEnabled = true
        template.isAlbumArtistButtonEnabled = item.type == .episode
    }
}
