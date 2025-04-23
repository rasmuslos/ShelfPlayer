//
//  CarPlayLibraryController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
@preconcurrency import CarPlay
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
        
        setupObservers()
        updateSections()
    }
}

private extension CarPlayAudiobookLibraryController {
    func updateSections() {
        updateTask?.cancel()
        updateTask = .detached {
            /*
            guard let (rows, _): ([HomeRow<Audiobook>], [HomeRow<Author>]) = try? await AudiobookshelfClient.shared.home(libraryID: self.library.id) else {
                return
            }
            
            let sections = HomeRow.prepareForPresentation(rows).map {
                let items = $0.entities.map(CarPlayHelper.buildAudiobookListItem)
                let section = CPListSection(items: items,
                                            header: $0.localizedLabel,
                                            headerSubtitle: nil,
                                            headerImage: nil,
                                            headerButton: nil,
                                            sectionIndexTitle: nil)
                
                return section
            }
            
            guard !Task.isCancelled else {
                return
            }
            
            self.template.updateSections(sections)
             */
        }
    }
    
    func setupObservers() {
        /*
        NotificationCenter.default.addObserver(forName: AudioPlayer.itemDidChangeNotification, object: nil, queue: nil) { [weak self] _ in
            self?.updateSections()
        }
         */
        
        // TODO: Update progress
    }
}
