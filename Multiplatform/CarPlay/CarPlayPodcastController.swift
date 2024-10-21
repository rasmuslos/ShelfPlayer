//
//  CarPlayPodcastController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

internal class CarPlayPodcastController {
    private let interfaceController: CPInterfaceController
    private let podcast: Podcast
    
    let template: CPListTemplate
    private var updateTask: Task<Void, Never>?
    
    init(interfaceController: CPInterfaceController, podcast: Podcast) {
        self.interfaceController = interfaceController
        self.podcast = podcast
        
        template = .init(title: podcast.name, sections: [], assistantCellConfiguration: .none)
        
        setupObservers()
        updateSections()
    }
}

private extension CarPlayPodcastController {
    func updateSections() {
        updateTask?.cancel()
        updateTask = .detached {
            guard let episodes = try? await AudiobookshelfClient.shared.episodes(podcastId: self.podcast.id) else {
                return
            }
            
            let filter = Defaults[.episodesFilter(podcastId: self.podcast.id)]
            let sortOrder = Defaults[.episodesSortOrder(podcastId: self.podcast.id)]
            let ascending = Defaults[.episodesAscending(podcastId: self.podcast.id)]
            
            let sorted = Episode.filterSort(episodes: episodes, filter: filter, sortOrder: sortOrder, ascending: ascending)
            let items = await sorted.parallelMap(CarPlayHelper.buildEpisodeListItem)
            let section = CPListSection(items: items, header: nil, sectionIndexTitle: nil)
            
            guard !Task.isCancelled else {
                return
            }
            
            self.template.updateSections([section])
        }
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(forName: AudioPlayer.itemDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updateSections()
        }
        
        // TODO: Update progress
    }
}
