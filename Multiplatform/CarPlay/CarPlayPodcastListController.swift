//
//  CarPlayPodcastListController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayerKit

internal class CarPlayPodcastListController {
    private let interfaceController: CPInterfaceController
    private let library: Library
    
    let template: CPListTemplate
    private var updateTask: Task<Void, Never>?
    
    init(interfaceController: CPInterfaceController, library: Library) {
        self.interfaceController = interfaceController
        self.library = library
        
        template = .init(title: library.name, sections: [], assistantCellConfiguration: .none)
        updateSections()
    }
}

private extension CarPlayPodcastListController {
    func updateSections() {
        updateTask?.cancel()
        updateTask = .detached {
            /*
            guard let podcasts = try? await AudiobookshelfClient.shared.podcasts(libraryID: self.library.id, limit: nil, page: nil).0 else {
                return
            }
            
            let items = podcasts.sorted { $0.sortName < $1.sortName }.map { podcast in
                let item = CPListItem(text: podcast.name, detailText: podcast.authors.formatted(.list(type: .and, width: .short)), image: nil)
                
                Task {
                    item.setImage(await podcast.cover?.platformImage)
                }
                
                item.handler = { _, completion in
                    Task {
                        let controller = CarPlayPodcastController(interfaceController: self.interfaceController, podcast: podcast)
                        try await self.interfaceController.pushTemplate(controller.template, animated: true)
                        completion()
                    }
                }
                
                return item
            }
            
            guard !Task.isCancelled else {
                return
            }
            
            let section = CPListSection(items: items, header: nil, sectionIndexTitle: nil)
            self.template.updateSections([section])
             */
        }
    }
}
