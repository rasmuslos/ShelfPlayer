//
//  AudiobookRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPPlayback

struct AudiobookRow: View {
    let audiobook: Audiobook
    let entity: OfflineProgress
    
    @MainActor
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        entity = OfflineManager.shared.requireProgressEntity(item: audiobook)
    }
    
    var labelImage: String {
        if audiobook == AudioPlayer.shared.item {
            return AudioPlayer.shared.playing ? "waveform" : "pause"
        } else {
            return "play"
        }
    }
    
    var body: some View {
        HStack {
            AudiobookCover(audiobook: audiobook)
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
                        
                        if entity.progress > 0 {
                            Text(entity.readableProgress(spaceConstrained: false))
                        } else {
                            Text(verbatim: audiobook.duration.timeLeft(spaceConstrained: false))
                        }
                    }
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.top, 1)
                }
                .buttonStyle(.plain)
            }
            .padding(.leading, 5)
        }
        .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
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
}
