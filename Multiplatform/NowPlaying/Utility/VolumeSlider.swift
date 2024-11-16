//
//  VolumeSlider.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import MediaPlayer
import SPPlayback

internal extension NowPlaying {
    struct VolumeSlider: View {
        @Binding var dragging: Bool
        
        @State private var volume = AudioPlayer.shared.volume
        
        var body: some View {
            Slider(percentage: $volume, displayed: .init() { volume } set: {
                if let volume = $0 {
                    self.volume = volume
                }
            }, dragging: $dragging)
                .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.volumeDidChangeNotification)) { _ in
                    if !dragging {
                        volume = AudioPlayer.shared.volume
                    }
                }
                .onChange(of: volume) {
                    if dragging {
                        AudioPlayer.shared.volume = volume
                    }
                }
        }
    }
}
