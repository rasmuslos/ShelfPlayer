//
//  CarPlayController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
@preconcurrency import CarPlay

final class CarPlayController {
    private let tabBarController: CarPlayTabBar
    private let nowPlayingController: CarPlayNowPlayingController
    
    init(interfaceController: CPInterfaceController) async throws {
        tabBarController = CarPlayTabBar(interfaceController: interfaceController)
        nowPlayingController = CarPlayNowPlayingController(interfaceController: interfaceController)
        
        try await interfaceController.setRootTemplate(tabBarController.template, animated: false)
    }
    
    func destroy() {
        nowPlayingController.remove()
    }
}
