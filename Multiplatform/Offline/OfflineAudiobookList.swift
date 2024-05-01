//
//  OfflineAudiobookList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPBase
import SPOffline
import SPPlayback

struct OfflineAudiobookList: View {
    let audiobooks: [Audiobook]
    
    var body: some View {
        ForEach(audiobooks.sorted()) { audiobook in
            Button {
                audiobook.startPlayback()
            } label: {
                AudiobookRow(audiobook: audiobook)
                    .modifier(SwipeActionsModifier(item: audiobook))
            }
            .buttonStyle(.plain)
        }
    }
}

extension OfflineAudiobookList {
    struct AudiobookRow: View {
        let audiobook: Audiobook
        let entity: ItemProgress
        
        @MainActor
        init(audiobook: Audiobook) {
            self.audiobook = audiobook
            entity = OfflineManager.shared.requireProgressEntity(item: audiobook)
        }
        
        var body: some View {
            HStack {
                Group {
                    if AudioPlayer.shared.item == audiobook {
                        Label("playing", systemImage: "waveform")
                            .labelStyle(.iconOnly)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: AudioPlayer.shared.playing)
                    } else {
                        ItemImage(image: audiobook.image)
                    }
                }
                .frame(width: 50, height: 50)
                
                VStack(alignment: .leading) {
                    Text(audiobook.name)
                        .modifier(SerifModifier())
                        .lineLimit(1)
                    
                    if let author = audiobook.author {
                        Text(author)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                ProgressIndicator(entity: entity)
                    .frame(width: 20)
            }
        }
    }
}

#Preview {
    List {
        OfflineAudiobookList(audiobooks: .init(repeating: [.fixture], count: 7))
    }
}
