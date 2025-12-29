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
    func updateTemplate() {
        Task {
            var controllers = [CarPlayItemController]()
            var sections = [CPListSection]()
            
            #warning("grr")
//            let listenNowControllers = await ShelfPlayerKit.listenNowItems.map { CarPlayPlayableItemController(item: $0, displayCover: true) }
            let listenNowControllers = [CarPlayPlayableItemController]()
            
            controllers += listenNowControllers
            sections.append(CPListSection(items: listenNowControllers.map(\.row), header: String(localized: "panel.listenNow"), sectionIndexTitle: nil))
            
            if let audiobooks = try? await PersistenceManager.shared.download.audiobooks() {
                let audiobookControllers = audiobooks.map { CarPlayPlayableItemController(item: $0, displayCover: true) }
                
                controllers += audiobookControllers
                sections.append(CPListSection(items: audiobookControllers.map(\.row), header: String(localized: "row.downloaded.audiobooks"), headerSubtitle: nil, headerImage: nil, headerButton: nil, sectionIndexTitle: nil))
            }
            
            if let podcasts = try? await PersistenceManager.shared.download.podcasts(), let episodes = try? await PersistenceManager.shared.download.episodes() {
                let grouped = Dictionary(grouping: episodes, by: \.podcastID).sorted { $0.key.description < $1.key.description }
                
                for (podcastID, contained) in grouped {
                    guard let podcast = podcasts.first(where: { $0.id == podcastID }) else {
                        continue
                    }
                    
                    let items = contained.map { CarPlayPlayableItemController(item: $0, displayCover: false) }
                    let section = CPListSection(items: items.map(\.row), header: podcast.name, headerSubtitle: podcast.authors.formatted(.list(type: .and, width: .short)), headerImage: await podcast.id.platformImage(size: .small), headerButton: nil, sectionIndexTitle: nil)
                    
                    sections.append(section)
                    controllers += items
                }
            }
            
            await MainActor.run {
                itemControllers = controllers
                template.updateSections(sections)
            }
        }
    }
}
