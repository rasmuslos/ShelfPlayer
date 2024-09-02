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
            HStack {
                Button {
                    AudioPlayer.shared.volume = 0
                } label: {
                    Label("mute", systemImage: "speaker.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
                
                Slider(percentage: $volume, dragging: $dragging)
                
                Button {
                    AudioPlayer.shared.volume = 1
                } label: {
                    Label("volume.max", systemImage: "speaker.wave.3.fill")
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.plain)
            }
            .saturation(1.6)
            .dynamicTypeSize(dragging ? .xLarge : .medium)
            .frame(height: 0)
            .animation(.easeInOut, value: dragging)
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
