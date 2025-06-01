//
//  CarPlayPodcastController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayback

@MainActor
class CarPlayPodcastController {
    private let interfaceController: CPInterfaceController
    private let podcast: Podcast
    
    let template: CPListTemplate
    
    private var image: UIImage?
    private var itemControllers = [CarPlayItemController]()
    
    init(interfaceController: CPInterfaceController, podcast: Podcast) {
        self.interfaceController = interfaceController
        self.podcast = podcast
        
        template = .init(title: podcast.name, sections: [], assistantCellConfiguration: .none)
        
        template.emptyViewTitleVariants = [String(localized: "item.empty")]
        template.emptyViewSubtitleVariants = [String(localized: "item.empty.description")]
        
        if #available(iOS 18.4, *) {
            template.showsSpinnerWhileEmpty = true
        }
        
        loadImage()
        loadEpisodes()
    }
    
    private nonisolated func loadImage() {
        Task {
            let image = await podcast.id.platformCover(size: .regular)
            
            await MainActor.run {
                self.image = image
                updateSection()
            }
        }
    }
    private nonisolated func loadEpisodes() {
        Task {
            let (_, episodes) = try await podcast.id.resolvedComplex
            
            let filter = Defaults[.episodesFilter(podcast.id)]
            let seasonFilter = Defaults[.episodesSeasonFilter(podcast.id)]
            let sortOrder = Defaults[.episodesSortOrder(podcast.id)]
            let ascending = Defaults[.episodesAscending(podcast.id)]
            
            let sorted = await Podcast.filterSort(episodes, filter: filter, seasonFilter: seasonFilter, restrictToPersisted: false, search: nil, sortOrder: sortOrder, ascending: ascending)
            
            await MainActor.run {
                itemControllers = sorted.map { CarPlayPlayableItemController(item: $0, displayCover: false) }
                
                updateSection()
                
                if #available(iOS 18.4, *) {
                    template.showsSpinnerWhileEmpty = false
                }
            }
        }
    }
    private func updateSection() {
        template.updateSections([
            CPListSection(items: itemControllers.map(\.row), header: podcast.name, headerSubtitle: podcast.authors.formatted(.list(type: .and, width: .short)), headerImage: image, headerButton: nil, sectionIndexTitle: nil)
        ])
    }
}
