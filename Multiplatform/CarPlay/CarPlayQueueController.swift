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
    }
}

private extension CarPlayQueueController {
    func updateSections() {
        updateTask?.cancel()
        updateTask = .detached {
            let items = await AudioPlayer.shared.queue.enumerated().compactMap { ($0, $1) }.parallelMap { index, item in
                let listItem: CPListItem
                
                if let audiobook = item as? Audiobook {
                    listItem = await CarPlayHelper.buildAudiobookListItem(audiobook: audiobook)
                } else if let episode = item as? Episode {
                    listItem = await CarPlayHelper.buildEpisodeListItem(episode: episode)
                } else {
                    listItem = .init(text: ":F", detailText: "somehow invalid item type in queue?")
                }
                
                listItem.handler = { _, completion in
                    Task {
                        try await AudioPlayer.shared.advance(to: index)
                        completion()
                    }
                }
                
                return listItem
            }
            
            guard !Task.isCancelled else {
                return
            }
            
            let section = CPListSection(items: items)
            self.template.updateSections([section])
        }
    }
}
