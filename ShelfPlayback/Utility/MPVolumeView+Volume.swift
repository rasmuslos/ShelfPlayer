//
//  MPVolumeView+Volume.swift
//  ShelfPlayback
//
//  Created by Rasmus Krämer on 25.08.24.
//

import Foundation
import MediaPlayer

#if os(iOS)
extension MPVolumeView {
    @MainActor
    static func setVolume(_ volume: Float) {
        let volumeView = MPVolumeView()
        let slider = volumeView.subviews.first(where: { $0 is UISlider }) as? UISlider

        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(10))
            slider?.value = volume
        }
    }
}
#endif
