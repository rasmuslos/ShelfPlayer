//
//  CarPlayOfflineTemplate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
@preconcurrency import CarPlay
import ShelfPlayback

@MainActor
final class CarPlayListenNowController {
    private let interfaceController: CPInterfaceController
    
    let template: CPListTemplate
    
    private var itemControllers = [CarPlayItemController]()
    
    @MainActor
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        template = .init(title: String(localized: "panel.listenNow"), sections: [], assistantCellConfiguration: .init(position: .top, visibility: .always, assistantAction: .playMedia))
        
        template.tabTitle = String(localized: "panel.listenNow")
        template.tabImage = UIImage(systemName: "house.fill")
        
        template.emptyViewTitleVariants = [String(localized: "item.empty")]
        template.emptyViewSubtitleVariants = [String(localized: "item.empty.description")]
        
        updateTemplate()
        
        RFNotification[.downloadStatusChanged].subscribe { [weak self] _ in
            self?.updateTemplate()
        }
    }
}

private extension CarPlayListenNowController {
    nonisolated func updateTemplate() {
        Task {
            let (sections, controllers) = await withTaskGroup {
                $0.addTask { await self.buildListenNowSection() }
                
                $0.addTask { await self.buildPersistedAudiobooksSection() }
                $0.addTask { await self.buildPersistedEpisodesSection() }
                
                var sections = [CPListSection]()
                var controllers = [CarPlayItemController]()
                
                for await (rows, itemControllers) in $0 {
                    sections += rows
                    controllers += itemControllers
                }
                
                return (sections, controllers)
            }
            
            await MainActor.run {
                itemControllers = controllers
                template.updateSections(sections)
            }
        }
    }
    
    nonisolated func buildListenNowSection() async -> ([CPListSection], [CarPlayItemController]) {
        let listenNowItems = await ShelfPlayerKit.listenNowItems
        
        guard !listenNowItems.isEmpty else {
            return ([], [])
        }
        
        return await MainActor.run {
            let controllers = listenNowItems.map { CarPlayPlayableItemController(item: $0, displayCover: true) }
            return ([CPListSection(items: controllers.map(\.row), header: "panel.listenNow", sectionIndexTitle: nil)], controllers)
        }
    }
    nonisolated func buildPersistedAudiobooksSection() async -> ([CPListSection], [CarPlayItemController]) {
        let audiobooks = try? await PersistenceManager.shared.download.audiobooks()
        
        guard let audiobooks else {
            return ([], [])
        }
        
        return await MainActor.run {
            let controllers = audiobooks.map { CarPlayPlayableItemController(item: $0, displayCover: true) }
            let section = CPListSection(items: controllers.map(\.row), header: String(localized: "row.downloaded.audiobooks"), headerSubtitle: nil, headerImage: nil, headerButton: nil, sectionIndexTitle: nil)
            
            return ([section], controllers)
        }
    }
    nonisolated func buildPersistedEpisodesSection() async -> ([CPListSection], [CarPlayItemController]) {
        let (podcasts, episodes) = (try? await PersistenceManager.shared.download.podcasts(), try? await PersistenceManager.shared.download.episodes())
        
        guard let podcasts, let episodes else {
            return ([], [])
        }
        
        let grouped = Dictionary(grouping: episodes, by: \.podcastID).sorted { $0.key.description < $1.key.description }
        
        let images = await withTaskGroup {
            for podcast in podcasts {
                $0.addTask {
                    (podcast.id, await podcast.id.platformCover(size: .small))
                }
            }
            
            return await $0.reduce(into: [:]) {
                $0[$1.0] = $1.1
            }
        }
        
        return await MainActor.run {
            var sections = [CPListSection]()
            var controllers = [CarPlayItemController]()
            
            for (podcastID, contained) in grouped {
                guard let podcast = podcasts.first(where: { $0.id == podcastID }) else {
                    continue
                }
                
                let items = contained.map { CarPlayPlayableItemController(item: $0, displayCover: false) }
                let section = CPListSection(items: items.map(\.row), header: podcast.name, headerSubtitle: podcast.authors.formatted(.list(type: .and, width: .short)), headerImage: images[podcastID], headerButton: nil, sectionIndexTitle: nil)
                
                sections.append(section)
                controllers += items
            }
            
            return (sections, controllers)
        }
    }
}
