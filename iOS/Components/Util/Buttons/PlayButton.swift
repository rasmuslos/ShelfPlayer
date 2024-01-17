//
//  PlayButton.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import SwiftUI
import SPBaseKit
import SPOfflineKit
import SPPlaybackKit

struct PlayButton: View {
    let item: PlayableItem
    
    @State var labelImage: String = "play.fill"
    @State var progress: OfflineProgress?
    
    var body: some View {
        let label = item as? Audiobook != nil ? String(localized: "listen") : String(localized: "play")
        
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
        .onAppear(perform: fetchProgress)
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.startStopNotification), perform: { _ in
            checkPlaying()
        })
        .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPauseNotification), perform: { _ in
            checkPlaying()
        })
        .onReceive(NotificationCenter.default.publisher(for: OfflineManager.progressCreatedNotification)) { _ in
            fetchProgress()
        }
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
    
    @MainActor
    private func fetchProgress() {
        progress = OfflineManager.shared.getProgressEntity(item: item)
    }
}

#Preview {
    PlayButton(item: Audiobook.fixture)
}
