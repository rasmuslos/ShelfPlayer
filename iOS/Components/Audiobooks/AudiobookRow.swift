//
//  AudiobookRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import AudiobooksKit

struct AudiobookRow: View {
    let audiobook: Audiobook
    
    @State var bottomText: String?
    @State var labelImage: String = "play"
    
    var body: some View {
        HStack {
            ItemProgressImage(item: audiobook)
                .frame(width: 85)
            
            VStack(alignment: .leading) {
                let topText = getTopText()
                if topText.count > 0 {
                    Text(topText.joined(separator: " • "))
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                
                Text(audiobook.name)
                    .font(.headline)
                    .fontDesign(.serif)
                    .lineLimit(1)
                
                Button {
                    audiobook.startPlayback()
                } label: {
                    HStack {
                        Image(systemName: labelImage)
                            .font(.title3)
                            .imageScale(.large)
                            .symbolVariant(.circle.fill)
                            .symbolEffect(.variableColor.iterative, isActive: labelImage == "waveform")
                        
                        if let bottomText = bottomText {
                            Text(bottomText)
                        } else {
                            Text("")
                                .onAppear(perform: fetchRemainingTime)
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 5)
            .onAppear(perform: checkPlaying)
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.startStopNotification), perform: { _ in
                checkPlaying()
            })
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPauseNotification), perform: { _ in
                checkPlaying()
            })
        }
    }
}

// MARK: Helper

extension AudiobookRow {
    private func getTopText() -> [String] {
        var parts = [String]()
        
        if let author = audiobook.author {
            parts.append(author)
        }
        if let released = audiobook.released {
            parts.append(released)
        }
        
        return parts
    }
    
    func fetchRemainingTime() {
        Task.detached {
            if let progress = await OfflineManager.shared.getProgress(item: audiobook) {
                bottomText = progress.readableProgress(spaceConstrained: false)
            } else {
                bottomText = audiobook.duration.timeLeft(spaceConstrained: false)
            }
        }
    }
    
    private func checkPlaying() {
        withAnimation {
            if audiobook == AudioPlayer.shared.item {
                labelImage = AudioPlayer.shared.isPlaying() ? "waveform" : "pause"
            } else {
                labelImage = "play"
            }
        }
    }
}
