//
//  CarPlayLibraryController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
import CarPlay
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
            
            var sections = [CPListSection]()
            
            for row in rows {
                let audiobooks = row.entities
                
                if row.id == "continue-listening" && audiobooks.count <= CPMaximumNumberOfGridImages {
                    let items = await audiobooks.parallelMap {
                        let image: UIImage
                        
                        if let data = await $0.cover?.data, let uiImage = UIImage(data: data) {
                            image = uiImage
                        } else {
                            image = .logo
                        }
                        
                        return (image, $0.name)
                    }
                    
                    let item = CPListImageRowItem(text: row.localizedLabel, images: items.map(\.0), imageTitles: items.map(\.1))
                    
                    item.isEnabled = false
                    item.listImageRowHandler = { _, index, completion in
                        let audiobook = audiobooks[index]
                        
                        Task {
                            try await AudioPlayer.shared.play(audiobook)
                            completion()
                        }
                    }
                    
                    sections.append(CPListSection(items: [item], header: nil, sectionIndexTitle: nil))
                } else {
                    let items = await row.entities.parallelMap(CarPlayHelper.buildAudiobookListItem)
                    let section = CPListSection(items: items,
                                                header: row.localizedLabel,
                                                headerSubtitle: nil,
                                                headerImage: nil,
                                                headerButton: nil,
                                                sectionIndexTitle: nil)
                    
                    sections.append(section)
                }
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
