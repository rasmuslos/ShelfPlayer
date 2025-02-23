//
//  AudiobookList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

struct AudiobookList: View {
    let sections: [AudiobookSection]
    let onAppear: ((_ section: AudiobookSection) -> Void)
    
    var body: some View {
        ForEach(sections) { section in
            Group {
                switch section {
                case .audiobook(let audiobook):
                    Row(audiobook: audiobook)
                case .series(let seriesID, let seriesName, let audiobookIDs):
                    NavigationLink(destination: ItemLoadView(seriesID)) {
                        SeriesList.ListItem(name: seriesName, audiobookIDs: audiobookIDs)
                    }
                    .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
                }
            }
            .onAppear {
                onAppear(section)
            }
        }
    }
}

private struct Row: View {
    @Environment(Satellite.self) private var satellite
    
    @Environment(\.displayContext) private var displayContext
    @Environment(\.colorScheme) private var colorScheme
    
    let audiobook: Audiobook
    
    @State private var progressEntity: ProgressEntity.UpdatingProgressEntity?
    
    private var icon: String {
        /*
        if audiobook == nowPlayingViewModel.item {
            return nowPlayingViewModel.playing ? "waveform.circle.fill" : "pause.circle.fill"
        } else {
            return "play.circle.fill"
        }
         */
        ""
    }
    
    private var progressVisible: Bool {
        // progressEntity.progress > 0 && progressEntity.progress < 1
        true
    }
    
    private var additional: [String] {
        var parts = [String]()
        
        if case .series(let series) = displayContext, let formattedSequence = audiobook.series.first(where: { $0.name == series.name })?.formattedSequence {
            parts.append("#\(formattedSequence)")
        }
        
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
        
        func appendDuration() {
            parts.append(audiobook.duration.formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2)))
        }
        
        if let progressEntity {
            if progressEntity.isFinished {
                parts.append(String(localized: "finished"))
            } else if progressEntity.progress <= 0 {
                appendDuration()
                /*
            } else if nowPlayingViewModel.item == audiobook, nowPlayingViewModel.itemDuration > 0 {
                parts.append(progressEntity.progress.formatted(.percent.notation(.compactName)))
                parts.append((nowPlayingViewModel.itemDuration - nowPlayingViewModel.itemCurrentTime).formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2)))
                 */
            } else {
                parts.append(progressEntity.progress.formatted(.percent.notation(.compactName)))
                parts.append(((progressEntity.duration ?? audiobook.duration) - progressEntity.currentTime).formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2)))
            }
        } else {
            appendDuration()
        }
        
        return parts
    }
    
    var body: some View {
        NavigationLink(destination: AudiobookView(audiobook)) {
            HStack(spacing: 12) {
                Button {
                    satellite.play(audiobook)
                } label: {
                    ItemProgressIndicatorImage(item: audiobook, size: .small, aspectRatio: .none)
                        .frame(width: 94)
                        .overlay {
                            if satellite.isLoading {
                                ZStack {
                                    Color.black
                                        .opacity(0.2)
                                        .clipShape(.rect(cornerRadius: 8))
                                    
                                    ProgressIndicator(tint: .white)
                                }
                            }
                        }
                }
                .buttonStyle(.plain)
                .disabled(satellite.isLoading)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(audiobook.name)
                        .lineLimit(2)
                        .font(.headline)
                        .modifier(SerifModifier())
                    
                    Group {
                        if case .author = displayContext, let seriesName = audiobook.seriesName {
                            Text(seriesName)
                        } else if !audiobook.authors.isEmpty {
                            Text(audiobook.authors, format: .list(type: .and, width: .short))
                        }
                    }
                    .lineLimit(2)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    
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
        .modifier(SwipeActionsModifier(item: audiobook, loading: .constant(false)))
        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
        .onAppear {
            fetchProgressEntity()
        }
    }
    
    private nonisolated func fetchProgressEntity() {
        Task {
            let entity = await PersistenceManager.shared.progress[audiobook.id].updating
            
            await MainActor.withAnimation {
                self.progressEntity = entity
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            AudiobookList(sections: .init(repeating: .audiobook(audiobook: .fixture), count: 7)) { _ in }
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}
#endif
