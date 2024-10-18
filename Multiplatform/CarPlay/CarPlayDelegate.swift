//
//  CarPlayDelegate.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.02.24.
//

import CarPlay
import ShelfPlayerKit

public final class CarPlayDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    internal var controller: CarPlayController?
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        // TODO: Check authorization
        
        controller = .init(interfaceController: interfaceController)
    }
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        controller = nil
    }
}
