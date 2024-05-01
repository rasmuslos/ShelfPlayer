//
//  AudiobookList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPBase
import SPOffline
import SPPlayback

struct AudiobookList: View {
    let audiobooks: [Audiobook]
    
    var body: some View {
        ForEach(audiobooks) { audiobook in
            NavigationLink(destination: AudiobookView(audiobook: audiobook)) {
                AudiobookRow(audiobook: audiobook)
            }
            .modifier(SwipeActionsModifier(item: audiobook))
            .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
        }
    }
}

extension AudiobookList {
    struct AudiobookRow: View {
        let audiobook: Audiobook
        let entity: ItemProgress
        
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
        
        var eyebrow: [String] {
            var parts = [String]()
            
            if let author = audiobook.author {
                parts.append(author)
            }
            if let released = audiobook.released {
                parts.append(released)
            }
            
            return parts
        }
        
        var body: some View {
            HStack {
                ItemStatusImage(item: audiobook, aspectRatio: .none)
                    .frame(width: 85)
                
                VStack(alignment: .leading, spacing: 0) {
                    if eyebrow.count > 0 {
                        Text(eyebrow.joined(separator: " • "))
                            .font(.caption.smallCaps())
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text(audiobook.name)
                        .font(.headline)
                        .modifier(SerifModifier())
                        .lineLimit(1)
                        .padding(.top, 4)
                        .padding(.bottom, 6)
                    
                    Button {
                        audiobook.startPlayback()
                    } label: {
                        HStack {
                            Image(systemName: labelImage)
                                .font(.subheadline)
                                .imageScale(.large)
                                .symbolVariant(.circle.fill)
                                .symbolEffect(.variableColor.iterative, isActive: labelImage == "waveform")
                            
                            if entity.progress > 0 {
                                Text(entity.readableProgress(spaceConstrained: false))
                            } else {
                                Text(verbatim: audiobook.duration.timeLeft(spaceConstrained: false))
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
                .padding(.leading, 5)
            }
            .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
        }
    }
}

#Preview {
    NavigationStack {
        List {
            AudiobookList(audiobooks: .init(repeating: [.fixture], count: 7))
        }
        .listStyle(.plain)
    }
}
