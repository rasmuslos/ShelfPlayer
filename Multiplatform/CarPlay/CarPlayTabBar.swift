//
//  CarPlayTabBar.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
@preconcurrency import CarPlay
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
        
        template = .init(templates: [listenNowController.template])
    }
    
    protocol LibraryTemplate {
        var template: CPListTemplate { get }
    }
}
