//
//  VolumeSlider.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import MediaPlayer

struct VolumeSlider: View {
    @State var volume: Double = 0
    @State var isDragging: Bool = false
    
    var body: some View {
        HStack {
            Image(systemName: "speaker.fill")
                .onTapGesture {
                    volume = 0.0
                }
            
            Slider(percentage: $volume, dragging: $isDragging)
            
            Image(systemName: "speaker.wave.3.fill")
                .onTapGesture {
                    volume = 100.0
                }
        }
        .dynamicTypeSize(isDragging ? .xLarge : .medium)
        .frame(height: 30)
        .onChange(of: volume) {
            if isDragging {
                MPVolumeView.setVolume(Float(volume / 100))
            }
        }
        .onReceive(AVAudioSession.sharedInstance().publisher(for: \.outputVolume), perform: { value in
            if !isDragging {
                withAnimation {
                    volume = Double(value) * 100
                }
            }
        })
    }
}
