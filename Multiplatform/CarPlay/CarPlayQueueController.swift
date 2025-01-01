//
//  CarPlayQueueController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
import CarPlay
import ShelfPlayerKit
import SPPlayback

internal final class CarPlayQueueController {
    private let interfaceController: CPInterfaceController
    
    let template: CPListTemplate
    private var updateTask: Task<Void, Never>?
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        template = .init(title: String(localized: "carPlay.queue.title"), sections: [], assistantCellConfiguration: .none)
        
        setupObservers()
        updateSections()
    }
}

private extension CarPlayQueueController {
    func updateSections() {
        updateTask?.cancel()
        updateTask = .detached {
            let items = AudioPlayer.shared.queue.enumerated().map { index, item in
                let listItem: CPListItem
                
                if let audiobook = item as? Audiobook {
                    listItem = CarPlayHelper.buildAudiobookListItem(audiobook)
                } else if let episode = item as? Episode {
                    listItem = CarPlayHelper.buildEpisodeListItem(episode, displayCover: true)
                } else {
                    listItem = .init(text: ":F", detailText: "somehow invalid item type in queue?")
                }
                
                listItem.handler = { _, completion in
                    Task {
                        try await AudioPlayer.shared.advance(to: index)
                        // completion()
                    }
                }
                
                return listItem
            }
            
            guard !Task.isCancelled else {
                return
            }
            
            let section = CPListSection(items: items)
            // self.template.updateSections([section])
        }
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(forName: AudioPlayer.queueDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updateSections()
        }
    }
}
