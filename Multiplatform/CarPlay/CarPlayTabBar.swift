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
    private var libraries: [Library: LibraryTemplate]
    
    let template: CPTabBarTemplate
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        listenNowController = .init(interfaceController: interfaceController)
        libraries = [:]
        
        template = .init(templates: [])
        updateTemplate()
        
        Task {
            for await _ in Defaults.updates([.carPlayShowListenNow]) {
                updateTemplate()
            }
        }
    }
    
    protocol LibraryTemplate {
        var template: CPListTemplate { get }
    }
    
    func updateTemplate() {
        var templates = [CPTemplate]()
        
        if Defaults[.carPlayShowListenNow] {
            templates.append(listenNowController.template)
        }
        
        if templates.isEmpty {
            templates.append(emptyTemplate)
        }
        
        template.updateTemplates(templates)
    }
    
    private var emptyTemplate: CPListTemplate {
        let template = CPListTemplate(title: nil, sections: [], assistantCellConfiguration: nil)
        
        template.tabTitle = String(localized: "carPlay.tabBar.empty")
        template.tabImage = UIImage(systemName: "xmark")
        
        template.emptyViewTitleVariants = [String(localized: "carPlay.tabBar.empty")]
        template.emptyViewSubtitleVariants = [String(localized: "carPlay.tabBar.empty.message")]
        
        return template
    }
}
