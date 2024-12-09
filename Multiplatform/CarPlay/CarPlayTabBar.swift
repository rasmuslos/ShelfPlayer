//
//  CarPlayTabBar.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
import CarPlay
import Defaults
import ShelfPlayerKit

internal final class CarPlayTabBar {
    private let interfaceController: CPInterfaceController
    private let offlineController: CarPlayOfflineController
    
    // The Task helps to prevent unnecessary image loading
    private var updateTask: Task<Void, Never>?
    private var libraries: [Library: LibraryTemplate]
    
    private let delegate: CarPlayTabBarDelegate
    internal let template: CPTabBarTemplate
    
    private var didSelectLastActiveLibrary: Bool
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        offlineController = .init(interfaceController: interfaceController)
        
        updateTask = nil
        libraries = [:]
        
        delegate = .init()
        template = .init(templates: [offlineController.template])
        
        didSelectLastActiveLibrary = false
        
        delegate.didSelect = didSelect
        template.delegate = delegate
        
        updateTemplates()
    }
    
    var truncateLibraries: Bool {
        libraries.count + 1 > CPTabBarTemplate.maximumTabCount
    }
    
    protocol LibraryTemplate {
        var template: CPListTemplate { get }
    }
}

private extension CarPlayTabBar {
    final class CarPlayTabBarDelegate: NSObject, CPTabBarTemplateDelegate {
        var didSelect: ((Library) -> Void)! = nil
        
        func tabBarTemplate(_ tabBarTemplate: CPTabBarTemplate, didSelect selectedTemplate: CPTemplate) {
            guard let userInfo = selectedTemplate.userInfo as? [String: Any], let library = userInfo["library"] as? Library else {
                return
            }
            
            didSelect(library)
        }
    }
    
    var librariesListTemplate: CPListTemplate {
        let items = libraries.map {
            let library = $0.key
            let template = $0.value.template
            
            let item = CPListItem(text: library.name,
                                  detailText: nil,
                                  image: .init(systemName: library.type == .podcasts ? "antenna.radiowaves.left.and.right" : "headphones"))
            
            item.handler = { _, completion in
                Task {
                    self.didSelect(library: library)
                    
                    // try await self.interfaceController.pushTemplate(template, animated: true)
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
                controller.template.userInfo = [
                    "library": library
                ]
                
                self.libraries[library] = controller
                templates.append(controller.template)
            }
            
            guard !Task.isCancelled else {
                return
            }
            
            let lastActiveTemplate = self.libraries.first(where: { $0.key.id == Defaults[.lastCarPlayTabValue] })?.value.template
            
            if self.truncateLibraries {
                var templates = [self.offlineController.template, self.librariesListTemplate]
                
                if let lastActiveTemplate {
                    templates.append(lastActiveTemplate)
                }
                
                self.template.updateTemplates(templates)
            } else {
                self.template.updateTemplates(templates)
            }
            
            if self.truncateLibraries, let lastActiveTemplate {
                self.template.select(lastActiveTemplate)
            }
            if !self.didSelectLastActiveLibrary, let template = self.libraries.first(where: { $0.key.id == Defaults[.lastCarPlayTabValue] })?.value.template {
                self.template.select(template)
                self.didSelectLastActiveLibrary = true
            }
        }
    }
    
    func didSelect(library: Library) {
        guard library.id != Defaults[.lastCarPlayTabValue] else {
            return
        }
        
        Defaults[.lastCarPlayTabValue] = library.id
        
        if self.truncateLibraries {
            updateTemplates()
        }
    }
}
