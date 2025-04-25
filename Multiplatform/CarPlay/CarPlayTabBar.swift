//
//  CarPlayTabBar.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayerKit

@MainActor
final class CarPlayTabBar {
    private let interfaceController: CPInterfaceController
    
    private let listenNowController: CarPlayListenNowController
    private var libraries: [Library: LibraryController]
    
    let template: CPTabBarTemplate
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        listenNowController = .init(interfaceController: interfaceController)
        libraries = [:]
        
        template = .init(templates: [])
        
        updateTemplate()
        updateLibraries()
        
        Task {
            for await _ in Defaults.updates([.carPlayTabBarLibraries, .carPlayShowListenNow, .carPlayShowOtherLibraries]) {
                updateTemplate()
            }
        }
    }
    
    @MainActor
    protocol LibraryController {
        var template: CPListTemplate { get }
    }
}

private extension CarPlayTabBar {
    func updateTemplate() {
        var templates = [CPTemplate]()
        
        if Defaults[.carPlayShowListenNow] {
            templates.append(listenNowController.template)
        }
        
        var libraries = libraries
        
        if let selection = Defaults[.carPlayTabBarLibraries] {
            for library in selection {
                guard let controller = libraries.removeValue(forKey: library) else {
                    Defaults[.carPlayTabBarLibraries]?.removeAll {
                        $0.id == library.id
                        && $0.connectionID == library.connectionID
                    }
                    
                    continue
                }
                
                templates.append(controller.template)
            }
        }
        
        if !libraries.isEmpty, Defaults[.carPlayShowOtherLibraries] {
            templates.append(otherLibrariesTemplate(libraries))
        }
        
        if templates.isEmpty {
            templates.append(emptyTemplate)
        }
        
        template.updateTemplates(templates)
    }
    nonisolated func updateLibraries() {
        Task {
            let connectionIDs = await PersistenceManager.shared.authorization.connections.keys
            
            let libraries = await withTaskGroup {
                for connectionID in connectionIDs {
                    $0.addTask {
                        try? await ABSClient[connectionID].libraries()
                    }
                }
                
                // return await $0.compactMap { $0 }.reduce([], +)
                return await $0.reduce([Library]()) {
                    if let libraries = $1 {
                        $0 + libraries
                    } else {
                        $0
                    }
                }
            }
            
            await MainActor.run {
                self.libraries = Dictionary(uniqueKeysWithValues: libraries.map {
                    ($0, CarPlayLibraryController(interfaceController: interfaceController, library: $0))
                })
                
                updateTemplate()
            }
        }
    }
    
    var emptyTemplate: CPListTemplate {
        let template = CPListTemplate(title: nil, sections: [], assistantCellConfiguration: nil)
        
        template.tabTitle = String(localized: "carPlay.tabBar.empty")
        template.tabImage = UIImage(systemName: "xmark")
        
        template.emptyViewTitleVariants = [String(localized: "carPlay.tabBar.empty")]
        template.emptyViewSubtitleVariants = [String(localized: "carPlay.tabBar.empty.message")]
        
        return template
    }
    func otherLibrariesTemplate(_ libraries: [Library: LibraryController]) -> CPListTemplate {
        let items = libraries.map { (library, controller) in
            let item = CPListItem(text: library.name, detailText: nil, image: UIImage(systemName: library.icon))
            
            item.handler = { _, completion in
                Task {
                    let _ = try? await self.interfaceController.pushTemplate(controller.template, animated: true)
                    completion()
                }
            }
            
            return item
        }
        
         let template = CPListTemplate(title: "carPlay.otherLibraries", sections: [CPListSection(items: items)], assistantCellConfiguration: nil)
        
        template.tabTitle = String(localized: "carPlay.otherLibraries")
        template.tabImage = UIImage(systemName: "ellipsis")
        
        return template
    }
}
