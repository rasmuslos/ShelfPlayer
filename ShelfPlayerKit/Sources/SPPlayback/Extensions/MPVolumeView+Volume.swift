//
//  MPVolumeView+Volume.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation
import MediaPlayer

#if os(iOS)
extension MPVolumeView {
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 0.01) {
            slider?.value = volume
        }
    }
}
#endif
