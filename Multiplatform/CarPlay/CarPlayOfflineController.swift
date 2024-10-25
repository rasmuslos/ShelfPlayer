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
            guard let audiobooks = try? OfflineManager.shared.audiobooks(), !audiobooks.isEmpty else {
                self.audiobooksListSection = nil
                return
            }
            
            let sorted = AudiobookSortFilter.sort(audiobooks: audiobooks,
                                                  order: Defaults[.offlineAudiobooksSortOrder],
                                                  ascending: Defaults[.offlineAudiobooksAscending])
            let items = await sorted.parallelMap(CarPlayHelper.buildAudiobookListItem)
            
            guard !Task.isCancelled else {
                return
            }
            
            self.audiobooksListSection = .init(items: items)
            
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
            
            for (podcast, episodes) in podcasts.sorted(by: { $0.key.sortName < $1.key.sortName }) {
                let items = await episodes.parallelMap { await CarPlayHelper.buildEpisodeListItem($0, displayCover: false) }
                let section = CPListSection(items: items,
                                            header: podcast.name,
                                            headerSubtitle: podcast.author,
                                            headerImage: await podcast.cover?.platformImage,
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
        
        Task {
            for await _ in Defaults.updates([.offlineAudiobooksAscending, .offlineAudiobooksSortOrder]) {
                updateAudiobooksSection()
            }
        }
        
        // TODO: Update progress
    }
}
