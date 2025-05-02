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
            for await _ in Defaults.updates([.carPlayTabBarLibraries, .carPlayShowListenNow, .carPlayShowOtherLibraries], initial: false) {
                updateTemplate()
            }
        }
        
        RFNotification[.connectionsChanged].subscribe { [weak self] _ in
            self?.updateLibraries()
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
                    templates.append(loadingLibraryTemplate)
                    
                    continue
                }
                
                templates.append(controller.template)
            }
        } else {
            templates.append(preferencesTipTemplate)
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
            let libraries = await ShelfPlayerKit.libraries
            
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
    var loadingLibraryTemplate: CPListTemplate {
        let template = emptyTemplate
        
        template.tabTitle = String(localized: "loading")
        template.tabImage = UIImage(systemName: "hourglass")
        
        template.emptyViewTitleVariants = [String(localized: "loading")]
        
        if #available(iOS 18.4, *) {
            template.showsSpinnerWhileEmpty = true
        }
        
        return template
    }
    var preferencesTipTemplate: CPListTemplate {
        let template = CPListTemplate(title: String(localized: "carPlay.tabBar.preferencesTip.message"), sections: [], assistantCellConfiguration: nil)
        
        template.tabTitle = String(localized: "carPlay.tabBar.preferencesTip")
        template.tabImage = UIImage(systemName: "plus.square.dashed")
        
        template.emptyViewTitleVariants = [String(localized: "carPlay.tabBar.preferencesTip")]
        template.emptyViewSubtitleVariants = [String(localized: "carPlay.tabBar.preferencesTip.message")]
        
        return template
    }
    
    func otherLibrariesTemplate(_ libraries: [Library: LibraryController]) -> CPListTemplate {
        let items = libraries.map { (library, controller) in
            let item = CPListItem(text: library.name, detailText: nil, image: UIImage(systemName: library.icon))
            
            item.handler = { [weak self] _, completion in
                Task {
                    let _ = try? await self?.interfaceController.pushTemplate(controller.template, animated: true)
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
