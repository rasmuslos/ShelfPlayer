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
        ForEach(Array(audiobooks.enumerated()), id: \.offset) { offset, audiobook in
            NavigationLink(destination: AudiobookView(audiobook: audiobook)) {
                AudiobookRow(audiobook: audiobook)
            }
            .modifier(SwipeActionsModifier(item: audiobook))
            .listRowSeparator(offset == 0 ? .hidden : .visible, edges: .top)
        }
    }
}

extension AudiobookList {
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
                ItemStatusImage(item: audiobook)
                    .frame(width: 85)
                
                VStack(alignment: .leading) {
                    if eyebrow.count > 0 {
                        Text(eyebrow.joined(separator: " • "))
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
}

extension AudiobookList {
    struct GridView: View {
        let title: String
        let audiobooks: [Audiobook]
        
        var body: some View {
            ScrollView {
                AudiobookVGrid(audiobooks: audiobooks)
                    .padding(.horizontal)
            }
            .navigationTitle(title)
        }
    }
}

#Preview {
    AudiobookList(audiobooks: .init(repeating: [.fixture], count: 7))
}
