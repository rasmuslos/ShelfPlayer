//
//  CarPlayDelegate.swift
//  iOS
//
//  Created by Rasmus Krämer on 23.02.24.
//

import CarPlay
import Defaults
import SPPlayback

class CarPlayDelegate: UIResponder, CPTemplateApplicationSceneDelegate {
    var interfaceController: CPInterfaceController?
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didConnect interfaceController: CPInterfaceController) {
        self.interfaceController = interfaceController
        
        Task {
            try? await interfaceController.setRootTemplate(nowPlayingTemplate, animated: true)
        }
    }
    
    func templateApplicationScene(_ templateApplicationScene: CPTemplateApplicationScene, didDisconnectInterfaceController interfaceController: CPInterfaceController) {
        self.interfaceController = nil
    }
}

extension CarPlayDelegate {
    var nowPlayingTemplate: CPNowPlayingTemplate {
        let template = CPNowPlayingTemplate.shared
        
        template.updateNowPlayingButtons([
            CPNowPlayingPlaybackRateButton() { _ in
                var rate = AudioPlayer.shared.playbackRate + Defaults[.playbackSpeedAdjustment]
                
                if rate > 2 {
                    rate = 0.25
                }
                
                AudioPlayer.shared.playbackRate = rate
            }
        ])
        
        return template
    }
}
