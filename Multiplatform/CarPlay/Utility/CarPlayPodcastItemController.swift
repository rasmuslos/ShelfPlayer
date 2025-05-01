//
//  CarPlayPodcastController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.05.25.
//

import Foundation
@preconcurrency import CarPlay
import ShelfPlayerKit
import SPPlayback

@MainActor
final class CarPlayPodcastItemController: CarPlayItemController {
    private let interfaceController: CPInterfaceController
    
    let podcast: Podcast
    let row: CPListItem
    
    init(interfaceController: CPInterfaceController, podcast: Podcast) {
        self.interfaceController = interfaceController
        self.podcast = podcast
        
        row = CPListItem(text: podcast.name, detailText: podcast.authors.formatted(.list(type: .and, width: .short)), image: nil)
        
        // row.handler = { [weak self] (_, completion) in
        row.handler = { (_, completion) in
            Task {
                try await interfaceController.pushTemplate(CarPlayPodcastController(interfaceController: interfaceController, podcast: podcast).template, animated: true)
                completion()
            }
        }
        
        Task {
            row.setImage(await podcast.id.platformCover(size: .regular))
        }
    }
}
