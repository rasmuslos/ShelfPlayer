//
//  CarPlayLibraryController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

internal class CarPlayAudiobookLibraryController: CarPlayTabBar.LibraryTemplate {
    private let interfaceController: CPInterfaceController
    private let library: Library
    
    internal let template: CPListTemplate
    private var updateTask: Task<Void, Never>?
    
    init(interfaceController: CPInterfaceController, library: Library) {
        self.interfaceController = interfaceController
        self.library = library
        
        updateTask = nil
        
        template = .init(title: library.name, sections: [], assistantCellConfiguration: .none)
        
        updateSections()
    }
}

private extension CarPlayAudiobookLibraryController {
    func updateSections() {
        updateTask?.cancel()
        updateTask = .detached {
            guard let (rows, _): ([HomeRow<Audiobook>], [HomeRow<Author>]) = try? await AudiobookshelfClient.shared.home(libraryID: self.library.id) else {
                return
            }
            
            let disableDiscoverRow = Defaults[.disableDiscoverRow]
            let hideFromContinueListening = Defaults[.hideFromContinueListening]
            
            let sections = await rows.filter {
                guard $0.id == "discover" else {
                    return !$0.entities.isEmpty
                }
                
                return !disableDiscoverRow && !$0.entities.isEmpty
            }.parallelMap { row in
                let audiobooks: [Audiobook] = {
                    guard row.id == "continue-listening" else {
                        return row.entities
                    }
                    
                    return row.entities.filter { audiobook in
                        !hideFromContinueListening.contains { $0.itemId == audiobook.id }
                    }
                }()
                
                let items = await row.entities.parallelMap(CarPlayHelper.buildAudiobookListItem)
                let section = CPListSection(items: items,
                                            header: row.localizedLabel,
                                            headerSubtitle: nil,
                                            headerImage: nil,
                                            headerButton: nil,
                                            sectionIndexTitle: nil)
                
                return section
            }
            
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
