//
//  CarPlayPodcastListController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayback

@MainActor
class CarPlayPodcastListController {
    private let interfaceController: CPInterfaceController
    private let library: Library
    
    let template: CPListTemplate
    
    private var itemControllers = [CarPlayItemController]()
    
    init(interfaceController: CPInterfaceController, library: Library) {
        self.interfaceController = interfaceController
        self.library = library
        
        template = .init(title: library.name, sections: [], assistantCellConfiguration: .none)
        
        template.emptyViewTitleVariants = [String(localized: "item.empty")]
        template.emptyViewSubtitleVariants = [String(localized: "item.empty.description")]
        
        if #available(iOS 18.4, *) {
            template.showsSpinnerWhileEmpty = true
        }
        
        updateSections()
    }
    
    private nonisolated func updateSections() {
        Task {
            let podcasts = try await ABSClient[library.connectionID].podcasts(from: library.id, sortOrder: Defaults[.podcastsSortOrder], ascending: Defaults[.podcastsAscending], limit: nil, page: nil).0
            
            await MainActor.run {
                itemControllers = podcasts.map { CarPlayPodcastItemController(interfaceController: interfaceController, podcast: $0) }
                template.updateSections([CPListSection(items: itemControllers.map(\.row))])
                
                if #available(iOS 18.4, *) {
                    template.showsSpinnerWhileEmpty = false
                }
            }
        }
    }
}
