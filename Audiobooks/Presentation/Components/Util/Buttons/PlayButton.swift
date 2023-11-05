//
//  PlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI

struct PlayButton: View {
    let item: PlayableItem
    @State var labelImage: String = "play.fill"
    
    var body: some View {
        let progress = OfflineManager.shared.getProgress(item: item)
        let label = item as? Audiobook != nil ? "Listen" : "Play"
        
        Button {
            item.startPlayback()
        } label: {
            if let progress = progress, progress.progress > 0 && progress.progress < 1 {
                Label {
                    Text(label)
                    + Text(verbatim: " • ")
                    + Text(String((progress.duration - progress.currentTime).timeLeft()))
                } icon: {
                    Image(systemName: labelImage)
                }
            } else {
                Label(label, systemImage: labelImage)
            }
        }
        .buttonStyle(PlayNowButtonStyle(percentage: progress?.progress ?? 0))
        .symbolEffect(.variableColor.iterative, isActive: labelImage == "waveform")
        .onAppear(perform: checkPlaying)
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.startStopNotification), perform: { _ in
            checkPlaying()
        })
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPauseNotification), perform: { _ in
            checkPlaying()
        })
    }
}

// MARK: Helper

extension PlayButton {
    private func checkPlaying() {
        withAnimation {
            if item == AudioPlayer.shared.item {
                labelImage = AudioPlayer.shared.isPlaying() ? "waveform" : "pause.fill"
            } else {
                labelImage = "play.fill"
            }
        }
    }
}

#Preview {
    PlayButton(item: Audiobook.fixture)
}
