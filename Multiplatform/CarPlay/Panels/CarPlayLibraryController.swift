//
//  CarPlayLibraryController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayback

@MainActor
class CarPlayLibraryController: CarPlayTabBar.LibraryController {
    private let interfaceController: CPInterfaceController
    private let library: Library
    
    let template: CPListTemplate
    
    private var itemControllers = [CarPlayItemController]()
    
    @MainActor
    init(interfaceController: CPInterfaceController, library: Library) {
        self.interfaceController = interfaceController
        self.library = library
        
        template = .init(title: library.name, sections: [], assistantCellConfiguration: .none)
        
        template.tabTitle = library.name
        template.tabImage = UIImage(systemName: library.icon)
        
        template.emptyViewTitleVariants = [String(localized: "item.empty")]
        template.emptyViewSubtitleVariants = [String(localized: "item.empty.description")]
        
        updateSections()
        
        RFNotification[.playbackItemChanged].subscribe { [weak self] (itemID, _, _) in
            guard itemID.connectionID == self?.library.connectionID else {
                return
            }
            
            self?.updateSections()
        }
    }
    
    private nonisolated func updateSections() {
        switch library.type {
        case .audiobooks:
            updateAudiobookSections()
        case .podcasts:
            updatePodcastSections()
        }
    }
    private func updateSections(_ sections: [(CPListSection, [CarPlayPlayableItemController])]) {
        itemControllers = sections.flatMap(\.1)
        template.updateSections(sections.map(\.0))
    }
    
    private nonisolated func updateAudiobookSections() {
        Task {
            let connectionID = library.connectionID
            
            let (rows, _): ([HomeRow<Audiobook>], [HomeRow<Person>]) = try await ABSClient[connectionID].home(for: library.id)
            let prepared = await HomeRow.prepareForPresentation(rows, connectionID: connectionID)
            
            await MainActor.run {
                let sections = prepared.map {
                    let items = $0.entities.map { CarPlayPlayableItemController(item: $0, displayCover: true) }
                    return (CPListSection(items: items.map(\.row), header: $0.localizedLabel, headerSubtitle: nil, headerImage: nil, headerButton: nil, sectionIndexTitle: nil), items)
                }
                
                itemControllers = sections.flatMap(\.1)
                template.updateSections(sections.map(\.0))
            }
        }
    }
    private nonisolated func updatePodcastSections() {
        Task {
            let connectionID = library.connectionID
            
            let (_, rows): ([HomeRow<Podcast>], [HomeRow<Episode>]) = try await ABSClient[connectionID].home(for: library.id)
            let prepared = await HomeRow.prepareForPresentation(rows, connectionID: connectionID)
            
            await MainActor.run {
                let sections = prepared.map {
                    let items = $0.entities.map { CarPlayPlayableItemController(item: $0, displayCover: true) }
                    return (CPListSection(items: items.map(\.row), header: $0.localizedLabel, headerSubtitle: nil, headerImage: nil, headerButton: nil, sectionIndexTitle: nil), items)
                }
                
                let item = CPListItem(text: String(localized: "panel.library"), detailText: nil)
                item.handler = { [weak self] (_, completion) in
                    guard let self else {
                        return
                    }
                    
                    let controller = CarPlayPodcastListController(interfaceController: interfaceController, library: library)
                    
                    Task {
                        try await interfaceController.pushTemplate(controller.template, animated: true)
                        completion()
                    }
                }
                
                itemControllers = sections.flatMap(\.1)
                template.updateSections([
                    CPListSection(items: [item]),
                ] + sections.map(\.0))
            }
        }
    }
}
