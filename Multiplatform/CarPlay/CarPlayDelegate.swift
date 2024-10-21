//
//  CarPlayDelegate.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.02.24.
//

import Foundation
import CarPlay
import Combine
import ShelfPlayerKit

public final class CarPlayDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    private var interfaceController: CPInterfaceController?
    
    private var controller: CarPlayController?
    private var apiClientSubscription: AnyCancellable?
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        registerAuthorizationSubscription()
        updateController(authorized: AudiobookshelfClient.shared.authorized)
    }
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        
        controller = nil
        apiClientSubscription = nil
    }
}

private extension CarPlayDelegate {
    private var unauthorizedTemplate: CPListTemplate {
        let unauthorizedTemplate = CPListTemplate(title: nil, sections: [], assistantCellConfiguration: .none)
        unauthorizedTemplate.emptyViewTitleVariants = [String(localized: "carPlay.unauthorized.title")]
        unauthorizedTemplate.emptyViewSubtitleVariants = [String(localized: "carPlay.unauthorized.subtitle")]
        
        return unauthorizedTemplate
    }
    
    private func registerAuthorizationSubscription() {
        apiClientSubscription = AudiobookshelfClient.shared.$authorized.sink { [weak self] authorized in
            self?.updateController(authorized: authorized)
        }
    }
    private func updateController(authorized: Bool) {
        guard let interfaceController else {
            return
        }
        
        if authorized {
            controller = .init(interfaceController: interfaceController)
        } else {
            controller = nil
            
            Task {
                try await interfaceController.setRootTemplate(unauthorizedTemplate, animated: false)
            }
        }
    }
}
