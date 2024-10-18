//
//  CarPlayOfflineTemplate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
import CarPlay
import ShelfPlayerKit
import SPPlayback

internal final class CarPlayOfflineController {
    private let interfaceController: CPInterfaceController
    
    private var audiobooksListSection: CPListSection?
    private var audiobooksUpdateTask: Task<Void, Never>?
    
    private var podcastsListSections: [CPListSection]?
    private var podcastsUpdateTask: Task<Void, Never>?
    
    let template: CPListTemplate
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        audiobooksListSection = nil
        audiobooksUpdateTask = nil
        
        template = CPListTemplate(title: String(localized: "carPlay.offline.title"),
                                  sections: [],
                                  assistantCellConfiguration: .init(position: .top, visibility: .always, assistantAction: .playMedia))
        
        template.emptyViewTitleVariants = [String(localized: "carPlay.offline.empty")]
        template.emptyViewSubtitleVariants = [String(localized: "carPlay.offline.empty.subtitle")]
        
        setupObservers()
        
        updateAudiobooksSection()
        updatePodcastsSection()
    }
}

private extension CarPlayOfflineController {
    func updateAudiobooksSection() {
        audiobooksUpdateTask?.cancel()
        audiobooksUpdateTask = Task.detached {
            guard let audiobooks = try? OfflineManager.shared.audiobooks() else {
                return
            }
            
            var items = await audiobooks.parallelMap(CarPlayHelper.buildAudiobookListItem)
            
            self.audiobooksListSection = CPListSection(items: items,
                                                  header: String(localized: "carPlay.offline.audiobooks"),
                                                  headerSubtitle: nil,
                                                  headerImage: UIImage(systemName: "book"),
                                                  headerButton: nil,
                                                  sectionIndexTitle: "BALLS")
            
            self.updateTemplate()
        }
    }
    
    func updatePodcastsSection() {
        podcastsUpdateTask?.cancel()
        podcastsUpdateTask = Task.detached {
            guard let podcasts = try? OfflineManager.shared.podcasts() else {
                return
            }
            
            self.podcastsListSections = []
            
            for (podcast, episodes) in podcasts {
                let image: UIImage?
                
                if let data = await podcast.cover?.data {
                    image = UIImage(data: data)
                } else {
                    image = nil
                }
                
                let episodeItems = await episodes.parallelMap(CarPlayHelper.buildEpisodeListItem)
                let section = CPListSection(items: episodeItems,
                                            header: podcast.name,
                                            headerSubtitle: podcast.author,
                                            headerImage: image,
                                            headerButton: nil,
                                            sectionIndexTitle: nil)
                
                self.podcastsListSections!.append(section)
            }
            
            self.updateTemplate()
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
        NotificationCenter.default.addObserver(forName: PlayableItem.downloadStatusUpdatedNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updateAudiobooksSection()
            self?.updatePodcastsSection()
        }
        
        NotificationCenter.default.addObserver(forName: AudioPlayer.itemDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updateAudiobooksSection()
            self?.updatePodcastsSection()
        }
        
        // TODO: Update progress
    }
}
