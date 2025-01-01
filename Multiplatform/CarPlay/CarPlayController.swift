//
//  CarPlayControlelr.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
import CarPlay
import Combine
import ShelfPlayerKit

internal class CarPlayController {
    private let interfaceController: CPInterfaceController
    
    private let tabBar: CarPlayTabBar
    private let nowPlayingController: CarPlayNowPlayingController
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        tabBar = .init(interfaceController: interfaceController)
        nowPlayingController = .init(interfaceController: interfaceController)
        
        Task {
            // try await interfaceController.setRootTemplate(tabBar.template, animated: false)
        }
    }
}
