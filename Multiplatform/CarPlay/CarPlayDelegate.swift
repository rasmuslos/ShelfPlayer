//
//  CarPlayDelegate.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.02.24.
//

import Foundation
import OSLog
@preconcurrency import CarPlay
import ShelfPlayback

@MainActor
public final class CarPlayDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    static let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "CarPlay")
    
    private var interfaceController: CPInterfaceController?
    private var controller: CarPlayController?
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.updateController()
        }
        
        updateController()
        
        Task {
            try await PersistenceManager.shared.authorization.waitForConnections()
        }
    }
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        
        controller?.destroy()
        controller = nil
    }
}

private extension CarPlayDelegate {
    var noConnectionsTemplate: CPListTemplate {
        let unauthorizedTemplate = CPListTemplate(title: nil, sections: [], assistantCellConfiguration: .none)
        unauthorizedTemplate.emptyViewTitleVariants = [String(localized: "carPlay.noConnections")]
        unauthorizedTemplate.emptyViewSubtitleVariants = [String(localized: "carPlay.noConnections.subtitle")]
        
        return unauthorizedTemplate
    }
    
    func updateController() {
        Task {
            guard let interfaceController else {
                Self.logger.warning("Attempted to update CarPlay controller before it was initialized.")
                return
            }
            
            guard await !PersistenceManager.shared.authorization.connectionIDs.isEmpty else {
                do {
                    try await interfaceController.setRootTemplate(noConnectionsTemplate, animated: false)
                } catch {
                    Self.logger.error("Failed to set no connections template: \(error)")
                }
                
                controller = nil
                
                return
            }
            
            if controller == nil {
                controller = try await CarPlayController(interfaceController: interfaceController)
            }
        }
    }
}
