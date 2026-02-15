//
//  CarPlayPodcastController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.05.25.
//

import Foundation
@preconcurrency import CarPlay
import ShelfPlayback

@MainActor
final class CarPlayPodcastItemController: CarPlayItemController {
    private let interfaceController: CPInterfaceController
    
    let podcast: Podcast
    let row: CPListItem
    
    init(interfaceController: CPInterfaceController, podcast: Podcast) {
        self.interfaceController = interfaceController
        self.podcast = podcast
        
        row = CPListItem(text: podcast.name, detailText: podcast.authors.formatted(.list(type: .and, width: .short)), image: nil)
        
        loadCover()
        
        // row.handler = { [weak self] (_, completion) in
        row.handler = { (_, completion) in
            Task {
                try await interfaceController.pushTemplate(CarPlayPodcastController(interfaceController: interfaceController, podcast: podcast).template, animated: true)
                completion()
            }
        }
        
        RFNotification[.reloadImages].subscribe { [weak self] itemID in
            if let itemID, self?.podcast.id != itemID {
                return
            }
            
            self?.loadCover()
        }
    }
    
    private func loadCover() {
        Task {
            let cover = await podcast.id.platformImage(size: .regular)
            
            row.setImage(cover)
        }
    }
}
