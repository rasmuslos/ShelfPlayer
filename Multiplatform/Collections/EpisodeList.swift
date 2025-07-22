//
//  LatestList.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import ShelfPlayback

struct EpisodeList: View {
    @Namespace private var namespace
    
    let episodes: [Episode]
    let context: PresentationContext
    
    @Binding var selected: [ItemIdentifier]?
    
    var body: some View {
        ForEach(episodes) { episode in
            let isSelected = selected?.contains(episode.id) == true
            
            HStack(spacing: 16) {
                Group {
                    if selected != nil {
                        Group {
                            Label("action.select", systemImage: "circle")
                                .foregroundStyle(Color.accentColor)
                                .labelStyle(.iconOnly)
                                .symbolVariant(selected?.contains(episode.id) == true ? .fill : .none)
                                .transition(.opacity)
                            
                            RowLabel(episode: episode, context: context, zoomID: nil)
                                .matchedGeometryEffect(id: "label-\(episode.id)", in: namespace)
                        }
                        .onTapGesture {
                            if isSelected {
                                selected?.removeAll {
                                    $0 == episode.id
                                }
                            } else {
                                selected?.append(episode.id)
                            }
                        }
                    } else {
                        Row(episode: episode, context: context)
                            .matchedGeometryEffect(id: "label-\(episode.id)", in: namespace)
                    }
                }
            }
            .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
            .listRowBackground(isSelected ? Color.gray.opacity(0.12) : .clear)
            .animation(.snappy, value: selected)
        }
    }
    
    enum PresentationContext {
        case latest
        case podcast
        case grid
        case featured
        case collection
    }
}

private struct Row: View {
    @Environment(\.namespace) private var namespace
    
    let episode: Episode
    let context: EpisodeList.PresentationContext
    
    @State private var zoomID = UUID()
    
    var body: some View {
        NavigationLink(value: NavigationDestination.item(episode, context == .grid ? zoomID : nil)) {
            RowLabel(episode: episode, context: context, zoomID: zoomID)
                .matchedTransitionSource(id: zoomID, in: namespace!)
                .padding(8)
                .universalContentShape(.rect(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .modifier(ItemStatusModifier(item: episode, hoverEffect: context.hoverEffect))
        .padding(-8)
    }
}
private struct RowLabel: View {
    @Environment(\.displayContext) private var displayContext
    @Environment(Satellite.self) private var satellite
    
    let episode: Episode
    let context: EpisodeList.PresentationContext
    let zoomID: UUID?
    
    var body: some View {
        HStack(spacing: 0) {
            if context.isImageVisible {
                Button {
                    satellite.start(episode.id, origin: displayContext.origin)
                } label: {
                    ItemImage(item: episode, size: .small)
                        .frame(width: 100)
                        .overlay {
                            if satellite.isLoading(observing: episode.id) {
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
                .disabled(satellite.isLoading(observing: episode.id))
                .hoverEffect(.highlight)
                .padding(.trailing, 8)
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
            
            Spacer(minLength: 0)
        }
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
        HStack(spacing: 8) {
            EpisodePlayButton(episode: episode, highlighted: context.isHighlighted)
                .modify {
                    if context.isHighlighted {
                        $0
                            .fixedSize()
                    } else {
                        $0
                    }
                }
            
            Group {
                if episode.type == .trailer {
                    Label("item.trailer", systemImage: "movieclapper.fill")
                } else if episode.type == .bonus {
                    Label("item.bonus", systemImage: "fireworks")
                }
            }
            .imageScale(.small)
            .font(.caption2)
            .labelStyle(.iconOnly)
            
            if !context.isActionDateHidden, let releaseDate = episode.releaseDate {
                Group {
                    if context.usesShortDateStyle {
                        Text(releaseDate, format: .dateTime.day(.twoDigits).month(.twoDigits))
                    } else {
                        Text(releaseDate, style: .date)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            
            Spacer(minLength: 4)
            
            if let status = download.status {
                switch status {
                case .downloading:
                    DownloadButton(itemID: episode.id, progressVisibility: .episode)
                case .completed:
                    Image(systemName: "arrow.down.circle.fill")
                        .font(.system(size: 10))
                        .foregroundStyle(.secondary)
                default:
                    EmptyView()
                }
            }
            
            Menu {
                PlayableItemContextMenuInner(item: episode, currentDownloadStatus: download.status)
            } label: {
                Label("item.options", systemImage: "ellipsis")
                    .labelStyle(.iconOnly)
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(8)
            }
            .buttonStyle(.plain)
            .padding(-8)
        }
    }
}

private extension EpisodeList.PresentationContext {
    var usesShortDateStyle: Bool {
        switch self {
            case .podcast: false
            default: true
        }
    }
    var isHighlighted: Bool {
        switch self {
            case .featured: true
            default: false
        }
    }
    var isImageVisible: Bool {
        switch self {
            case .podcast: false
            default: true
        }
    }
    var isActionDateHidden: Bool {
        switch self {
            case .featured: true
            default: false
        }
    }
    
    var lineLimit: Int {
        switch self {
            case .podcast: 3
            default: 2
        }
    }
    
    var hoverEffect: HoverEffect? {
        switch self {
            case .podcast: nil
            default: .highlight
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        List {
            EpisodeList(episodes: .init(repeating: .fixture, count: 1), context: .latest, selected: .constant(nil))
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}

#Preview {
    @Previewable @State var selected: [ItemIdentifier]? = []
    
    NavigationStack {
        List {
            EpisodeList(episodes: .init(repeating: .fixture, count: 1), context: .podcast, selected: $selected)
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}
#endif
