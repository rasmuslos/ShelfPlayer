//
//  CarPlayDelegate.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.02.24.
//

import CarPlay
import SPFoundation

public final class CarPlayDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    // we need to keep a strong reference to this object
    internal var nowPlayingObserver: NowPlayingObserver?
    internal var interfaceController: CPInterfaceController?
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        Task {
            // Check if the user is logged in
            if !AudiobookshelfClient.shared.authorized {
                try await interfaceController.presentTemplate(CPAlertTemplate(titleVariants: [String(localized: "carPlay.unauthorized.short"), String(localized: "carPlay.unauthorized")], actions: []), animated: true)
                
                return
            }
            
            nowPlayingObserver = updateNowPlayingTemplate()
            
            // Try to fetch libraries
            
            #if DEBUG
            /*
            if let libraries = try? await AudiobookshelfClient.shared.getLibraries() {
                
            }
             */
            #else
            try await interfaceController.setRootTemplate(try buildOfflineListTemplate(), animated: true)
            #endif
        }
    }
    
    public func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
        nowPlayingObserver = nil
    }
}
