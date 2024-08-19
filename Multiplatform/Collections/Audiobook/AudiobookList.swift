//
//  AudiobookList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPFoundation
import SPOffline
import SPPlayback

struct AudiobookList: View {
    let audiobooks: [Audiobook]
    
    var body: some View {
        ForEach(audiobooks) { audiobook in
            NavigationLink(destination: AudiobookView(viewModel: .init(audiobook: audiobook))) {
                Row(audiobook: audiobook)
            }
            .modifier(SwipeActionsModifier(item: audiobook))
            .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
        }
    }
}


private struct Row: View {
    let audiobook: Audiobook
    
    @State private var entity: ItemProgress? = nil
    
    private var labelImage: String {
        if audiobook == AudioPlayer.shared.item {
            return AudioPlayer.shared.playing ? "waveform" : "pause"
        } else {
            return "play"
        }
    }
    
    private var eyebrow: [String] {
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
        HStack(spacing: 12) {
            ItemStatusImage(item: audiobook, aspectRatio: .none)
                .frame(width: 88)
                .shadow(radius: 4)
            
            VStack(alignment: .leading, spacing: 0) {
                if !eyebrow.isEmpty {
                    Text(eyebrow.joined(separator: " • "))
                        .lineLimit(1)
                        .font(.caption.smallCaps())
                        .foregroundStyle(.secondary)
                        .padding(.bottom, 4)
                }
                
                Text(audiobook.name)
                    .lineLimit(1)
                    .font(.headline)
                    .modifier(SerifModifier())
                    .padding(.bottom, 8)
                
                Button {
                    audiobook.startPlayback()
                } label: {
                    HStack {
                        Label("playing", systemImage: labelImage)
                            .labelStyle(.iconOnly)
                            .font(.subheadline)
                            .imageScale(.large)
                            .symbolVariant(.circle.fill)
                            .symbolEffect(.variableColor.iterative, isActive: labelImage == "waveform")
                        
                        if let entity, entity.progress > 0 {
                            Text(entity.readableProgress(spaceConstrained: false))
                        } else {
                            Text(audiobook.duration.timeLeft(spaceConstrained: false))
                        }
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .modifier(ButtonHoverEffectModifier())
            }
        }
        .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
        .task {
            entity = OfflineManager.shared.requireProgressEntity(item: audiobook)
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
