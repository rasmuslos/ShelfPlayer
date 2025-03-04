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
    let onAppear: ((_: AudiobookSection) -> Void)
    
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
    @State private var progress: ProgressTracker
    
    init(audiobook: Audiobook) {
        self.audiobook = audiobook
        _progress = .init(initialValue: .init(itemID: audiobook.id))
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
        
        if let isFinished = progress.isFinished, isFinished {
            parts.append(String(localized: "finished"))
        } else if satellite.currentItemID == audiobook.id, satellite.duration > 0 {
            parts.append((satellite.duration - satellite.currentTime).formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1)))
        } else if let progress = progress.progress, progress <= 0 {
            appendDuration()
        } else if let progress = progress.progress, let currentTime = self.progress.currentTime {
            parts.append(progress.formatted(.percent.notation(.compactName)))
            parts.append(((self.progress.duration ?? audiobook.duration) - currentTime).formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2)))
        } else {
            appendDuration()
        }
        
        return parts
    }
    
    var body: some View {
        NavigationLink(destination: AudiobookView(audiobook)) {
            HStack(spacing: 12) {
                Button {
                    satellite.start(audiobook)
                } label: {
                    ItemProgressIndicatorImage(item: audiobook, size: .small, aspectRatio: .none)
                        .frame(width: 94)
                        .overlay {
                            if satellite.isLoading(observing: audiobook.id) {
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
                .disabled(satellite.isLoading(observing: audiobook.id))
                
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
                            .contentTransition(.numericText(countsDown: true))
                    }
                }
            }
        }
        .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
        .modifier(SwipeActionsModifier(item: audiobook, loading: .constant(false)))
        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
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
