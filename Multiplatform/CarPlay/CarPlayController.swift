//
//  CarPlayControlelr.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
@preconcurrency import CarPlay
import ShelfPlayback

@MainActor
class CarPlayController {
    private let interfaceController: CPInterfaceController
    
    private let tabBar: CarPlayTabBar
    private let nowPlayingController: CarPlayNowPlayingController
    
    init(interfaceController: CPInterfaceController) async throws {
        self.interfaceController = interfaceController
        
        tabBar = .init(interfaceController: interfaceController)
        nowPlayingController = .init(interfaceController: interfaceController)
        
        try await interfaceController.setRootTemplate(tabBar.template, animated: false)
    }
}
