//
//  CarPlayOfflineTemplate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

internal final class CarPlayOfflineController {
    private let interfaceController: CPInterfaceController
    
    private var audiobooksListSection: CPListSection?
    
    private var podcastsListSections: [CPListSection]?
    private var podcastsUpdateTask: Task<Void, Never>?
    
    let template: CPListTemplate
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        audiobooksListSection = nil
        
        template = CPListTemplate(title: String(localized: "carPlay.offline.title"),
                                  sections: [],
                                  assistantCellConfiguration: .init(position: .top, visibility: .always, assistantAction: .playMedia))
        
        template.tabImage = UIImage(systemName: "bookmark")
        template.tabTitle = String(localized: "carPlay.offline.tab")
        
        template.emptyViewTitleVariants = [String(localized: "carPlay.offline.empty")]
        template.emptyViewSubtitleVariants = [String(localized: "carPlay.offline.empty.subtitle")]
        
        setupObservers()
        
        updateAudiobooksSection()
        updatePodcastsSection()
    }
}

private extension CarPlayOfflineController {
    func updateAudiobooksSection() {
        /*
        guard let audiobooks = try? OfflineManager.shared.audiobooks(), !audiobooks.isEmpty else {
            self.audiobooksListSection = nil
            return
        }
        
        let sorted = Audiobook.sort(audiobooks,
                                    sortOrder: Defaults[.offlineAudiobooksSortOrder],
                                    ascending: Defaults[.offlineAudiobooksAscending])
        let items = sorted.map(CarPlayHelper.buildAudiobookListItem)
        
        guard !Task.isCancelled else {
            return
        }
        
        self.audiobooksListSection = .init(items: items)
        self.updateTemplate()
         */
    }
    
    func updatePodcastsSection() {
        podcastsUpdateTask?.cancel()
        podcastsUpdateTask = Task.detached {
            /*
            guard let podcasts = try? OfflineManager.shared.podcasts() else {
                return
            }
            
            self.podcastsListSections = []
            
            for (podcast, episodes) in podcasts.sorted(by: { $0.key.sortName < $1.key.sortName }) {
                let items = episodes.map { CarPlayHelper.buildEpisodeListItem($0, displayCover: false) }
                var image: UIImage? = nil
                
                for episode in episodes {
                    if let cover = await episode.cover?.platformImage {
                        image = cover
                        break
                    }
                }
                
                let section = CPListSection(items: items,
                                            header: podcast.name,
                                            headerSubtitle: podcast.authors.formatted(.list(type: .and, width: .short)),
                                            headerImage: image,
                                            headerButton: nil,
                                            sectionIndexTitle: nil)
                
                self.podcastsListSections!.append(section)
            }
            
            self.updateTemplate()
             */
        }
    }
    
    func updateTemplate() {
        var sections = [CPListSection]()
        
        if let audiobooksListSection {
            sections.append(audiobooksListSection)
        }
        if let podcastsListSections {
            sections += podcastsListSections
        }
        
        template.updateSections(sections)
    }
    
    func setupObservers() {
        /*
        NotificationCenter.default.addObserver(forName: PlayableItem.downloadStatusUpdatedNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updateAudiobooksSection()
            self?.updatePodcastsSection()
        }
         */
        
        /*
        NotificationCenter.default.addObserver(forName: AudioPlayer.itemDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updateAudiobooksSection()
            self?.updatePodcastsSection()
        }
         */
        
        Task {
            /*
            for await _ in Defaults.updates([.offlineAudiobooksAscending, .offlineAudiobooksSortOrder]) {
                // updateAudiobooksSection()
            }
             */
        }
        
        // TODO: Update progress
    }
}
