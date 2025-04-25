//
//  CarPlayOfflineTemplate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

@MainActor
final class CarPlayListenNowController {
    private let interfaceController: CPInterfaceController
    
    let template: CPListTemplate
    
    private var itemControllers = [CarPlayItemController]()
    
    @MainActor
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        template = .init(title: String(localized: "carPlay.listenNow"), sections: [], assistantCellConfiguration: .init(position: .top, visibility: .always, assistantAction: .playMedia))
        
        template.tabTitle = String(localized: "carPlay.listenNow")
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
            return ([CPListSection(items: controllers.map(\.row), header: "row.listenNow", sectionIndexTitle: nil)], controllers)
        }
    }
    nonisolated func buildPersistedAudiobooksSection() async -> ([CPListSection], [CarPlayItemController]) {
        do {
            let audiobooks = try await PersistenceManager.shared.download.audiobooks()
            
            guard !audiobooks.isEmpty else {
                return ([], [])
            }
            
            return await MainActor.run {
                let controllers = audiobooks.map { CarPlayPlayableItemController(item: $0, displayCover: true) }
                let section = CPListSection(items: controllers.map(\.row), header: String(localized: "row.downloaded.audiobooks"), headerSubtitle: nil, headerImage: nil, headerButton: nil, sectionIndexTitle: nil)
                
                return ([section], controllers)
            }
        } catch {
            await CarPlayDelegate.logger.error("Failed to load audiobooks: \(error)")
            return ([], [])
        }
    }
}

/*
 if #available(iOS 18.4, *) {
     template.showsSpinnerWhileEmpty = true
 }
 */
