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

    let offlineController: CarPlayOfflineController
    
    let template: CPTabBarTemplate
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        offlineController = .init(interfaceController: interfaceController)
        offlineController.template.tabImage = UIImage(systemName: "bookmark")
        offlineController.template.tabTitle = String(localized: "carPlay.offline.tab")
        
        template = .init(templates: [offlineController.template])
    }
    
    private func updateTemplates() {
        
    }
}
