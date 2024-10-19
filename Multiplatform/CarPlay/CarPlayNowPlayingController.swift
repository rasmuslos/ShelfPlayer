//
//  CarPlayNowPlayingController.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 19.10.24.
//

import Foundation
import CarPlay
import Defaults
import ShelfPlayerKit
import SPPlayback

internal class CarPlayNowPlayingController {
    let template = CPNowPlayingTemplate.shared
    
    func configureNowPlayingTemplate(interfaceController: CPInterfaceController) {
        let rateButton = CPNowPlayingPlaybackRateButton { _ in
            var rate = AudioPlayer.shared.playbackRate + Defaults[.playbackSpeedAdjustment]
            
            if rate > 2 {
                rate = 0.25
            }
            
            AudioPlayer.shared.playbackRate = rate
        }
        
        // let moreButton = CPNowPlayingMoreButton(handler: <#T##((CPNowPlayingButton) -> Void)?##((CPNowPlayingButton) -> Void)?##(CPNowPlayingButton) -> Void#>)
        
        template.updateNowPlayingButtons([rateButton])
    }
}
