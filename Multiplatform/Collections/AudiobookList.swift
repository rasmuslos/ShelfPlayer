//
//  AudiobookList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import ShelfPlayback

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
                        NavigationLink(value: NavigationDestination.itemID(seriesID)) {
                            SeriesList.ListItem(name: seriesName, audiobookIDs: audiobookIDs)
                        }
                        .buttonStyle(.plain)
                        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
                        .modifier(ItemStatusModifier(itemID: seriesID, hoverEffect: nil))
                }
            }
            .onAppear {
                onAppear(section)
            }
        }
    }
    
    struct Row<Content: View>: View {
        @Environment(Satellite.self) private var satellite
        
        @Environment(\.displayContext) private var displayContext
        @Environment(\.colorScheme) private var colorScheme
        
        let audiobook: Audiobook
        let trailingContent: Content
        
        @State private var progress: ProgressTracker
        
        init(audiobook: Audiobook, @ViewBuilder content: @escaping () -> Content) {
            self.audiobook = audiobook
            self.trailingContent = content()
            
            _progress = .init(initialValue: .init(itemID: audiobook.id))
        }
        
        private var additional: [String] {
            var parts = [String]()
            
            if case .series(let series) = displayContext, let formattedSequence = audiobook.series.first(where: { $0.name == series.name })?.formattedSequence {
                parts.append("#\(formattedSequence)")
            }
            
            if let released = audiobook.released {
                parts.append(released)
            }
            
            func appendDuration() {
                parts.append(audiobook.duration.formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2)))
            }
            
            if let isFinished = progress.isFinished, isFinished {
                parts.append(String(localized: "item.progress.finished"))
            } else if satellite.nowPlayingItemID == audiobook.id, satellite.duration > 0 {
                parts.append((satellite.duration - satellite.currentTime).formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 1)))
            } else if let progress = progress.progress, progress <= 0 {
                appendDuration()
            } else if let progress = progress.progress, let currentTime = self.progress.currentTime {
                parts.append(progress.formatted(.percent.notation(.compactName)))
                parts.append(((self.progress.duration ?? audiobook.duration) - currentTime).formatted(.duration(unitsStyle: .brief, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2)))
            } else {
                appendDuration()
            }
            
            if audiobook.explicit && audiobook.abridged {
                parts.append("🅴🅰")
            } else if audiobook.explicit {
                parts.append("🅴")
            } else if audiobook.abridged {
                parts.append("🅰")
            }
            
            return parts
        }
        var hasTrailingContent: Bool {
            trailingContent as? EmptyView == nil
        }
        
        var body: some View {
            NavigationLink(value: NavigationDestination.item(audiobook)) {
                HStack(spacing: 0) {
                    Button {
                        satellite.start(audiobook.id, origin: displayContext.origin)
                    } label: {
                        ItemProgressIndicatorImage(itemID: audiobook.id, size: .small, aspectRatio: .none)
                            .frame(width: 80)
                            .overlay {
                                if satellite.isLoading(observing: audiobook.id) {
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
                    .disabled(satellite.isLoading(observing: audiobook.id))
                    .hoverEffect(.highlight)
                    .padding(.trailing, 12)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(audiobook.name)
                            .lineLimit(2)
                            .bold()
                            .font(.callout)
                        
                        Group {
                            if case .person(let person) = displayContext, person.id.type == .author, let seriesName = audiobook.seriesName {
                                Text(seriesName)
                                    .lineLimit(2)
                            } else if !audiobook.authors.isEmpty {
                                HStack(spacing: 0) {
                                    Text(audiobook.authors, format: .list(type: .and, width: .short))
                                    
                                    if !audiobook.narrators.isEmpty {
                                        Text(verbatim:  " • ")
                                        Text(audiobook.narrators, format: .list(type: .and, width: .short))
                                    }
                                }
                                .lineLimit(1)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        if !additional.isEmpty {
                            Text(additional.joined(separator: " • "))
                                .lineLimit(1)
                                .font(.caption.smallCaps())
                                .foregroundStyle(.secondary)
                                .padding(.top, 4)
                                .contentTransition(.numericText(countsDown: true))
                        }
                    }
                    
                    Spacer(minLength: hasTrailingContent ? 8 : 0)
                    
                    if hasTrailingContent {
                        trailingContent
                    }
                }
                .universalContentShape(.rect(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
            .modifier(ItemStatusModifier(item: audiobook, hoverEffect: nil))
        }
    }
}

extension AudiobookList.Row where Content == EmptyView {
    init(audiobook: Audiobook) {
        self.init(audiobook: audiobook, content: { EmptyView() })
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
