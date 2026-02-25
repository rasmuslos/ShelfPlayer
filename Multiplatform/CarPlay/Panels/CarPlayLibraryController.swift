//
//  CarPlayLibraryController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//
import Foundation
@preconcurrency import CarPlay
import ShelfPlayback

final class CarPlayLibraryController {
    private let library: Library
    
    let template: CPListTemplate
    
    private var itemControllers = [CarPlayItemController]()
    private var refreshTask: Task<Void, Never>?
    
    init(library: Library) {
        self.library = library
        
        template = CPListTemplate(title: library.name, sections: [], assistantCellConfiguration: .none)
        template.tabTitle = library.name
        template.tabImage = UIImage(systemName: library.icon)
        template.applyCarPlayLoadingState()
        
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.reload()
        }
        RFNotification[.offlineModeChanged].subscribe { [weak self] _ in
            self?.reload()
        }
        
        reload()
    }
    
    deinit {
        refreshTask?.cancel()
    }
}

private extension CarPlayLibraryController {
    func reload() {
        refreshTask?.cancel()
        template.applyCarPlayLoadingState()
        
        refreshTask = Task { [weak self] in
            guard let self else {
                return
            }
            
            switch library.id.type {
            case .audiobooks:
                await self.loadAudiobookHome()
            case .podcasts:
                await self.loadPodcastHome()
            }
        }
    }
    
    func loadAudiobookHome() async {
        do {
            let rows: ([HomeRow<Audiobook>], [HomeRow<Person>]) = try await ABSClient[library.id.connectionID].home(for: library.id.libraryID)
            let prepared = await HomeRow.prepareForPresentation(rows.0, connectionID: library.id.connectionID)
            
            var sections = [CPListSection]()
            var retainedControllers = [CarPlayItemController]()
            
            for row in prepared {
                let controllers = row.entities.map {
                    CarPlayPlayableItemController(item: $0, displayCover: true)
                }
                
                retainedControllers.append(contentsOf: controllers)
                sections.append(
                    CPListSection(
                        items: controllers.map(\.row),
                        header: row.localizedLabel,
                        sectionIndexTitle: nil
                    )
                )
            }
            
            applySections(sections, retainedControllers: retainedControllers)
        } catch {
            clearTemplate()
        }
    }
    
    func loadPodcastHome() async {
        do {
            let rows: ([HomeRow<Podcast>], [HomeRow<Episode>]) = try await ABSClient[library.id.connectionID].home(for: library.id.libraryID)
            let prepared = await HomeRow.prepareForPresentation(rows.1, connectionID: library.id.connectionID)
            
            var sections = [CPListSection]()
            var retainedControllers = [CarPlayItemController]()
            
            for row in prepared {
                let controllers = row.entities.map {
                    CarPlayPlayableItemController(item: $0, displayCover: true)
                }
                
                retainedControllers.append(contentsOf: controllers)
                sections.append(
                    CPListSection(
                        items: controllers.map(\.row),
                        header: row.localizedLabel,
                        sectionIndexTitle: nil
                    )
                )
            }
            
            applySections(sections, retainedControllers: retainedControllers)
        } catch {
            clearTemplate()
        }
    }
    
    func applySections(_ sections: [CPListSection], retainedControllers: [CarPlayItemController]) {
        itemControllers = retainedControllers
        template.updateSections(sections)
        template.applyCarPlayEmptyState()
    }
    
    func clearTemplate() {
        itemControllers = []
        template.updateSections([])
        template.applyCarPlayEmptyState()
    }
}
