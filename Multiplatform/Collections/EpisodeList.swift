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
    }
}


private struct Row: View {
    @Environment(Satellite.self) private var satellite
    @Environment(\.namespace) private var namespace
    
    let episode: Episode
    let context: EpisodeList.PresentationContext
    
    let download: DownloadStatusTracker
    
    init(episode: Episode, context: EpisodeList.PresentationContext) {
        self.episode = episode
        self.context = context
        
        download = .init(itemID: episode.id)
    }
    
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
                        satellite.play(episode)
                    } label: {
                        ItemImage(item: episode, size: .small)
                            .frame(width: 104)
                            .padding(.trailing, 12)
                            .hoverEffect(.highlight)
                            .matchedTransitionSource(id: zoomID, in: namespace!)
                    }
                    .buttonStyle(.plain)
                }
                
                VStack(alignment: .leading, spacing: 0) {
                    Text(episode.name)
                        .lineLimit(1)
                        .bold()
                        .font(.callout)
                    
                    if let description = episode.descriptionText {
                        Text(description)
                            .lineLimit(context == .podcast ? 3 : 2)
                            .multilineTextAlignment(.leading)
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 4)
                    }
                    
                    HStack(spacing: 0) {
                        EpisodePlayButton(episode: episode)
                        
                        if let releaseDate = episode.releaseDate {
                            Group {
                                switch context {
                                case .podcast:
                                    Text(releaseDate, style: .date)
                                default:
                                    Text(releaseDate, format: .dateTime.day(.twoDigits).month(.twoDigits))
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
