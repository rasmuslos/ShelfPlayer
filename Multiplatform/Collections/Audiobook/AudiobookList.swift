//
//  AudiobookList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

internal struct AudiobookList: View {
    let audiobooks: [Audiobook]
    var onAppear: ((_ audiobook: Audiobook) -> Void)? = nil
    
    var body: some View {
        ForEach(audiobooks) { audiobook in
            if let onAppear {
                Row(audiobook: audiobook)
                    .onAppear { onAppear(audiobook) }
            } else {
                Row(audiobook: audiobook)
            }
        }
    }
}

private struct Row: View {
    @Environment(NowPlaying.ViewModel.self) private var nowPlayingViewModel
    @Environment(\.colorScheme) private var colorScheme
    
    let audiobook: Audiobook
    
    @State private var loading = false
    @State private var progressEntity: ProgressEntity
    
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: audiobook))
        progressEntity.beginReceivingUpdates()
    }
    
    private var icon: String {
        if audiobook == nowPlayingViewModel.item {
            return nowPlayingViewModel.playing ? "waveform.circle.fill" : "pause.circle.fill"
        } else {
            return "play.circle.fill"
        }
    }
    
    private var progressVisible: Bool {
        progressEntity.progress > 0 && progressEntity.progress < 1
    }
    
    private var additional: [String] {
        var parts = [String]()
        
        if audiobook.explicit && audiobook.abridged {
            parts.append("🅴🅰")
        } else if audiobook.explicit {
            parts.append("🅴")
        } else if audiobook.abridged {
            parts.append("🅰")
        }
        
        if let released = audiobook.released {
            parts.append(released)
        }
        
        if progressEntity.progress >= 1 {
            parts.append(String(localized: "finished"))
        } else if progressEntity.progress <= 0 {
            parts.append(audiobook.duration.formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2)))
        } else if nowPlayingViewModel.item == audiobook, nowPlayingViewModel.itemDuration > 0 {
            parts.append(progressEntity.progress.formatted(.percent.notation(.compactName)))
            parts.append((nowPlayingViewModel.itemDuration - nowPlayingViewModel.itemCurrentTime).formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2)))
        } else {
            parts.append(progressEntity.progress.formatted(.percent.notation(.compactName)))
            parts.append((progressEntity.duration - progressEntity.currentTime).formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2)))
        }
        
        return parts
    }
    
    var body: some View {
        NavigationLink(destination: AudiobookView(audiobook)) {
            HStack(spacing: 12) {
                Button {
                    Task {
                        loading = true
                        try? await AudioPlayer.shared.play(audiobook)
                        loading = false
                    }
                } label: {
                    ItemStatusImage(item: audiobook, aspectRatio: .none)
                        .frame(width: 88)
                        .shadow(radius: 4)
                        .overlay {
                            if loading {
                                ZStack {
                                    Color.black
                                        .opacity(0.2)
                                        .clipShape(.rect(cornerRadius: 8))
                                    
                                    ProgressView()
                                        .tint(.white)
                                }
                            }
                        }
                }
                .buttonStyle(.plain)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(audiobook.name)
                        .lineLimit(2)
                        .font(.headline)
                        .modifier(SerifModifier())
                    
                    if let author = audiobook.author {
                        Text(author)
                            .lineLimit(2)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    if !additional.isEmpty {
                        Text(additional.joined(separator: " • "))
                            .lineLimit(1)
                            .font(.caption.smallCaps())
                            .foregroundStyle(.secondary)
                            .padding(.top, 6)
                    }
                }
            }
        }
        .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
        .modifier(SwipeActionsModifier(item: audiobook, loading: $loading))
        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            AudiobookList(audiobooks: .init(repeating: [.fixture], count: 7))
        }
        .listStyle(.plain)
    }
    .environment(NowPlaying.ViewModel())
}
#endif
