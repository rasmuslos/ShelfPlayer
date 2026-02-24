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

public final class CarPlayDelegate: UIResponder {
    let logger = Logger(subsystem: "io.rfk.shelfPlayer", category: "CarPlay")
    
    private var interfaceController: CPInterfaceController?
    private var controller: CarPlayController?
    
    override init() {
        super.init()
        
        RFNotification[.connectionsChanged].subscribe { [weak self] in
            self?.refreshController()
        }
    }
}

extension CarPlayDelegate: CPTemplateApplicationSceneDelegate {
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        refreshController()
    }
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        controller?.destroy()
        controller = nil
    }
}

private extension CarPlayDelegate {
    var noConnectionsTemplate: CPListTemplate {
        let template = CPListTemplate(title: nil, sections: [], assistantCellConfiguration: .none)
        template.emptyViewTitleVariants = [String(localized: "carPlay.noConnections")]
        template.emptyViewSubtitleVariants = [String(localized: "carPlay.noConnections.subtitle")]
        
        return template
    }
    func refreshController() {
        Task { [weak self] in
            guard let self else {
                return
            }
            
            guard let interfaceController else {
                logger.warning("Attempted to refresh CarPlay before interface controller was initialized.")
                return
            }
            
            await OfflineMode.shared.ensureAvailabilityEstablished()
            
            let hasConnections = await !PersistenceManager.shared.authorization.connectionIDs.isEmpty
            
            guard hasConnections else {
                controller?.destroy()
                controller = nil
                
                do {
                    try await interfaceController.setRootTemplate(noConnectionsTemplate, animated: false)
                } catch {
                    logger.error("Failed to set CarPlay no-connections template: \(error)")
                }
                
                return
            }
            
            guard controller == nil else {
                return
            }
            
            do {
                controller = try await CarPlayController(interfaceController: interfaceController)
            } catch {
                logger.error("Failed to initialize CarPlay controller: \(error)")
            }
        }
    }
}
