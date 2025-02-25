//
//  LatestList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct EpisodeList: View {
    let episodes: [Episode]
    let context: PresentationContext
    
    var body: some View {
        ForEach(episodes) {
            Row(episode: $0, context: context)
        }
    }
    
    enum PresentationContext {
        case latest
        case podcast
        case grid
        case featured
    }
}


private struct Row: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.namespace) private var namespace
    
    let episode: Episode
    let context: EpisodeList.PresentationContext
    
    private let _zoomID = UUID()
    private var zoomID: UUID? {
        if context == .grid {
            return _zoomID
        }
        
        return nil
    }
    
    var body: some View {
        NavigationLink(destination: EpisodeView(episode, zoomID: zoomID)) {
            HStack(spacing: 0) {
                if context != .podcast {
                    Button {
                        satellite.start(episode)
                    } label: {
                        ItemImage(item: episode, size: .small)
                            .frame(width: 104)
                            .padding(.trailing, 12)
                            .hoverEffect(.highlight)
                            .matchedTransitionSource(id: zoomID, in: namespace!)
                            .overlay {
                                if satellite.isLoading(observing: episode.id) {
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
                    .disabled(satellite.isLoading(observing: episode.id))
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(episode.name)
                        .lineLimit(1)
                        .bold()
                        .font(.callout)
                    
                    if let description = episode.descriptionText {
                        Text(description)
                            .lineLimit(context.lineLimit)
                            .multilineTextAlignment(.leading)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    
                    EpisodeItemActions(episode: episode, context: context)
                    .padding(.top, 8)
                }
                
                Spacer()
            }
            .contentShape(.hoverMenuInteraction, .rect())
        }
        .buttonStyle(.plain)
        .modifier(SwipeActionsModifier(item: episode, loading: .constant(false)))
        .modifier(EpisodeContextMenuModifier(episode: episode))
        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}

struct EpisodeItemActions: View {
    let episode: Episode
    let context: EpisodeList.PresentationContext
    
    @State private var download: DownloadStatusTracker
    
    init(episode: Episode, context: EpisodeList.PresentationContext) {
        self.episode = episode
        self.context = context
        
        _download = .init(initialValue: .init(itemID: episode.id))
    }
    
    var body: some View {
        HStack(spacing: 0) {
            EpisodePlayButton(episode: episode, highlighted: context.isHighlighted)
                .modify {
                    if context.isHighlighted {
                        $0
                            .fixedSize()
                    } else {
                        $0
                    }
                }
            
            if let releaseDate = episode.releaseDate {
                Group {
                    if context.usesShortDateStyle {
                        Text(releaseDate, format: .dateTime.day(.twoDigits).month(.twoDigits))
                    } else {
                        Text(releaseDate, style: .date)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
                .padding(.leading, 8)
            }
            
            Spacer(minLength: 12)
            
            if let status = download.status {
                switch status {
                case .downloading:
                    DownloadButton(item: episode, progressVisibility: .episode)
                case .completed:
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                default:
                    EmptyView()
                }
            }
        }
    }
}

private extension EpisodeList.PresentationContext {
    var usesShortDateStyle: Bool {
        switch self {
        case .latest, .grid, .featured:
            true
        case .podcast:
            false
        }
    }
    var isHighlighted: Bool {
        switch self {
        case .featured:
            true
        case .grid, .latest, .podcast:
            false
        }
    }
    
    var lineLimit: Int {
        switch self {
        case .latest, .grid, .featured:
            2
        case .podcast:
            3
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            EpisodeList(episodes: .init(repeating: .fixture, count: 7), context: .latest)
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}

#Preview {
    NavigationStack {
        List {
            EpisodeList(episodes: .init(repeating: .fixture, count: 7), context: .podcast)
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}
#endif
