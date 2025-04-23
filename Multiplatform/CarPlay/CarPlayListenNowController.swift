//
//  CarPlayOfflineTemplate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 18.10.24.
//

import Foundation
@preconcurrency import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

@MainActor
final class CarPlayListenNowController {
    private let interfaceController: CPInterfaceController
    
    let template: CPListTemplate
    
    init(interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        template = .init(title: "carPlay.listenNow", sections: [], assistantCellConfiguration: .init(position: .top, visibility: .always, assistantAction: .playMedia))
        // template.showsSpinnerWhileEmpty = true
        
        updateTemplate()
    }
    
    nonisolated func updateTemplate() {
        Task {
            let listenNowItems = await ShelfPlayerKit.listenNowItems
            
            print(listenNowItems)
        }
    }
}
