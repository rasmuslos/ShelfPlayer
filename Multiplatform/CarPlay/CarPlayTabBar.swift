//
//  CarPlayTabBar.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
import CarPlay
import ShelfPlayerKit

internal final class CarPlayTabBar {
    private let interfaceController: CPInterfaceController
    private let offlineController: CarPlayOfflineController
    
    // The Task helps to prevent unnecessary image loading
    private var updateTask: Task<Void, Never>?
    private var libraries: [Library: LibraryTemplate]
    
    internal let template: CPTabBarTemplate
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        offlineController = .init(interfaceController: interfaceController)
        offlineController.template.tabImage = UIImage(systemName: "bookmark")
        offlineController.template.tabTitle = String(localized: "carPlay.offline.tab")
        
        updateTask = nil
        libraries = [:]
        
        template = .init(templates: [offlineController.template])
        
        updateTemplates()
    }
    
    protocol LibraryTemplate {
        var template: CPListTemplate { get }
    }
}

private extension CarPlayTabBar {
    var librariesListTemplate: CPListTemplate {
        let items = libraries.map {
            let library = $0.key
            let template = $0.value.template
            
            let item = CPListItem(text: library.name,
                                  detailText: nil,
                                  image: .init(systemName: library.type == .podcasts ? "antenna.radiowaves.left.and.right" : "headphones"))
            
            item.handler = { _, completion in
                Task {
                    try await self.interfaceController.pushTemplate(template, animated: true)
                    completion()
                }
            }
            
            return item
        }
        
        let section = CPListSection(items: items)
        return CPListTemplate(title: String(localized: "carPlay.libraries"), sections: [section], assistantCellConfiguration: .none)
    }
    
    func updateTemplates() {
        updateTask?.cancel()
        updateTask = .detached {
            guard let libraries = try? await AudiobookshelfClient.shared.libraries() else {
                return
            }
            
            var templates: [CPTemplate] = [self.offlineController.template]
            
            for library in libraries {
                let controller: CarPlayTabBar.LibraryTemplate
                
                switch library.type {
                case .audiobooks:
                    controller = CarPlayAudiobookLibraryController(interfaceController: self.interfaceController, library: library)
                    controller.template.tabImage = .init(systemName: "headphones")
                case .podcasts:
                    controller = CarPlayPodcastLibraryController(interfaceController: self.interfaceController, library: library)
                    controller.template.tabImage = .init(systemName: "antenna.radiowaves.left.and.right")
                default:
                    continue
                }
                
                controller.template.tabTitle = library.name
                
                self.libraries[library] = controller
                templates.append(controller.template)
            }
            
            guard !Task.isCancelled else {
                return
            }
            
            if templates.count > CPTabBarTemplate.maximumTabCount {
                self.template.updateTemplates([self.offlineController.template, self.librariesListTemplate])
            } else {
                self.template.updateTemplates(templates)
            }
        }
    }
}
