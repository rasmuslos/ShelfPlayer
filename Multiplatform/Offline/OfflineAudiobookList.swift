//
//  OfflineAudiobookList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

internal struct OfflineAudiobookList: View {
    let audiobooks: [Audiobook]
    
    var body: some View {
        ForEach(audiobooks) { audiobook in
            AudiobookRow(audiobook: audiobook)
                .listRowInsets(.init(top: audiobook == audiobooks.first ? 12 : 6, leading: 12, bottom: audiobook == audiobooks.last ? 12 : 6, trailing: 12))
        }
    }
    
    private enum Overlay: Identifiable, Codable, Hashable {
        case playing(active: Bool)
        case loading
        
        var id: Self {
            self
        }
    }
}

internal extension OfflineAudiobookList {
    struct AudiobookRow: View {
        let audiobook: Audiobook
        let entity: ProgressEntity?
        
        @MainActor
        init(audiobook: Audiobook) {
            self.audiobook = audiobook
            // entity = OfflineManager.shared.progressEntity(item: audiobook)
            entity = nil
        }
        
        @State private var loading = false
        
        private var overlay: Overlay? {
            /*
            if loading {
                return .loading
            } else if AudioPlayer.shared.item == audiobook {
                return .playing(active: true)
            }
             */
            
            return nil
        }
        
        var body: some View {
            Button {
                Task {
                    // try await AudioPlayer.shared.play(audiobook, withoutPlaybackSession: true)
                }
            } label: {
                HStack(spacing: 0) {
                    ItemImage(item: audiobook, size: .tiny, aspectRatio: .none)
                        .frame(width: 60)
                        .overlay {
                            if let overlay {
                                ZStack {
                                    Color.black.opacity(0.2)
                                    
                                    switch overlay {
                                        case .loading:
                                        ProgressIndicator(tint: .white)
                                        case .playing(let active):
                                            Label("playing", systemImage: "waveform")
                                                .labelStyle(.iconOnly)
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                                .symbolEffect(.variableColor.iterative.dimInactiveLayers, isActive: active)
                                    }
                                }
                            }
                        }
                        .padding(.trailing, 12)
                    
                    VStack(alignment: .leading) {
                        Text(audiobook.name)
                            .modifier(SerifModifier())
                            .lineLimit(1)
                        
                        if !audiobook.authors.isEmpty {
                            Text(audiobook.authors, format: .list(type: .and, width: .short))
                                .lineLimit(1)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer(minLength: 12)
                    
                    /*
                    CircularProgressIndicator(entity: entity)
                        .frame(width: 20)
                     */
                }
                .contentShape(.hoverMenuInteraction, .rect)
            }
            .buttonStyle(.plain)
            // .modifier(ItemSwipeActionsModifier(item: audiobook))
        }
    }
}

#if DEBUG
#Preview {
    List {
        OfflineAudiobookList(audiobooks: .init(repeating: .fixture, count: 7))
    }
}
#endif
