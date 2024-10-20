//
//  CarPlayPodcastLibraryController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.10.24.
//

import Foundation
import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

internal class CarPlayPodcastLibraryController: CarPlayTabBar.LibraryTemplate {
    private let interfaceController: CPInterfaceController
    private let library: Library
    
    internal let template: CPListTemplate
    private var updateTask: Task<Void, Never>?
    
    init(interfaceController: CPInterfaceController, library: Library) {
        self.interfaceController = interfaceController
        self.library = library
        
        updateTask = nil
        
        template = .init(title: library.name, sections: [], assistantCellConfiguration: .none)
        
        setupObservers()
        updateSections()
    }
}

private extension CarPlayPodcastLibraryController {
    func updateSections() {
        updateTask?.cancel()
        updateTask = .detached {
            guard let (_, rows): ([HomeRow<Podcast>], [HomeRow<Episode>]) = try? await AudiobookshelfClient.shared.home(libraryID: self.library.id) else {
                return
            }
            
            var sections = await HomeRow.prepareForPresentation(rows).parallelMap {
                let items = await $0.entities.parallelMap(CarPlayHelper.buildEpisodeListItem)
                let section = CPListSection(items: items,
                                            header: $0.localizedLabel,
                                            headerSubtitle: nil,
                                            headerImage: nil,
                                            headerButton: nil,
                                            sectionIndexTitle: nil)
                
                return section
            }
            
            let item = CPListItem(text: String(localized: "carPlay.podcasts.all"), detailText: nil)
            item.handler = { _, completion in
                Task {
                    let controller = CarPlayPodcastListController(interfaceController: self.interfaceController, library: self.library)
                    try await self.interfaceController.pushTemplate(controller.template, animated: true)
                    completion()
                }
            }
            
            sections.append(.init(items: [item], header: String(localized: "carPlay.podcasts.library"), sectionIndexTitle: nil))
            
            self.template.updateSections(sections)
        }
    }
    
    func setupObservers() {
        NotificationCenter.default.addObserver(forName: AudioPlayer.itemDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updateSections()
        }
        
        // TODO: Update progress
    }
}

