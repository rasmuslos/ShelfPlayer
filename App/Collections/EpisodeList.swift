//
//  EpisodeList.swift
//  ShelfPlayer
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

    struct Row: View {
        @Environment(\.namespace) private var namespace

        let episode: Episode
        let context: EpisodeList.PresentationContext

        @State private var zoomID = UUID()

        var body: some View {
            NavigationLink(value: NavigationDestination.item(episode, context == .grid ? zoomID : nil)) {
                RowLabel(episode: episode, context: context, zoomID: zoomID)
                    .contentShape(.rect)
                    .matchedTransitionSource(id: zoomID, in: namespace!)
                    .padding(8)
                    .universalContentShape(.rect(cornerRadius: 8))
            }
            .buttonStyle(.plain)
            .modifier(ItemStatusModifier(item: episode, hoverEffect: context.hoverEffect))
            .padding(-8)
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

private struct RowLabel: View {
    @Environment(\.displayContext) private var displayContext
    @Environment(Satellite.self) private var satellite

    @ScaledMetric(relativeTo: .headline) private var imageSize: CGFloat = 96
    @ScaledMetric(relativeTo: .headline) private var rightImageSize: CGFloat = 84

    let episode: Episode
    let context: EpisodeList.PresentationContext
    let zoomID: UUID?

    @ViewBuilder
    private var imageView: some View {
        Button {
            satellite.start(episode.id, origin: displayContext.origin)
        } label: {
            ItemImage(item: episode, size: .small)
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
    }

    @ViewBuilder
    private var titleColumn: some View {
        VStack(alignment: .leading, spacing: 4) {
            if context.dateAboveTitle, let releaseDate = episode.releaseDate {
                HStack(spacing: 6) {
                    Text(releaseDate, format: .relative(presentation: .named, unitsStyle: .abbreviated))

                    if episode.type == .trailer {
                        Label("item.trailer", systemImage: "movieclapper.fill")
                            .labelStyle(.iconOnly)
                    } else if episode.type == .bonus {
                        Label("item.bonus", systemImage: "fireworks")
                            .labelStyle(.iconOnly)
                    }
                }
                .font(.footnote.smallCaps())
                .foregroundStyle(.secondary)
            }

            Text(episode.name)
                .lineLimit(context.titleLineLimit)
                .font(.headline)

            if let description = episode.descriptionText {
                Text(description)
                    .font(.subheadline)
                    .lineLimit(context.descriptionLineLimit)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.secondary)
            }
        }
    }

    var body: some View {
        if context.isImageOnRight {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 12) {
                    titleColumn

                    Spacer(minLength: 0)

                    if context.isImageVisible {
                        imageView
                            .frame(width: rightImageSize, height: rightImageSize)
                    }
                }

                EpisodeItemActions(episode: episode, context: context)
            }
        } else {
            HStack(spacing: 0) {
                if context.isImageVisible {
                    imageView
                        .frame(width: imageSize)
                        .padding(.trailing, 8)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(episode.name)
                        .lineLimit(context.titleLineLimit)
                        .font(.headline)

                    if let description = episode.descriptionText {
                        Text(description)
                            .font(.subheadline)
                            .lineLimit(context.descriptionLineLimit)
                            .multilineTextAlignment(.leading)
                            .foregroundStyle(.secondary)
                    }

                    EpisodeItemActions(episode: episode, context: context)
                }

                Spacer(minLength: 0)
            }
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
                .modify(if: context.isHighlighted) {
                    $0
                        .fixedSize()
                }

            if !context.isActionDateHidden, let releaseDate = episode.releaseDate {
                Group {
                    if context.usesShortDateStyle {
                        Text(releaseDate, format: .dateTime.day(.twoDigits).month(.twoDigits))
                    } else {
                        Text(releaseDate, style: .date)
                    }
                }
                .font(.footnote.smallCaps())
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            if !context.dateAboveTitle {
                Group {
                    if episode.type == .trailer {
                        Label("item.trailer", systemImage: "movieclapper.fill")
                    } else if episode.type == .bonus {
                        Label("item.bonus", systemImage: "fireworks")
                    }
                }
                .imageScale(.small)
                .font(.caption)
                .labelStyle(.iconOnly)
            }

            if let status = download.status {
                switch status {
                    case .downloading:
                        DownloadButton(itemID: episode.id, progressVisibility: .episode)
                    case .completed:
                        Image(systemName: "arrow.down")
                            .font(.caption)
                            .symbolVariant(.circle.fill)
                            .symbolRenderingMode(.multicolor)
                            .foregroundStyle(.secondary.opacity(0.6))
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
        true
    }
    var isHighlighted: Bool {
        switch self {
            case .featured: true
            default: false
        }
    }
    var isImageVisible: Bool {
        switch self {
            case .featured, .grid: true
            case .latest, .collection: true
            case .podcast: false
        }
    }
    var isImageOnRight: Bool {
        switch self {
            case .podcast, .latest, .collection: true
            case .featured, .grid: false
        }
    }
    var dateAboveTitle: Bool {
        isImageOnRight
    }
    var isActionDateHidden: Bool {
        switch self {
            case .featured: true
            case .podcast, .latest, .collection: true
            case .grid: false
        }
    }
    var titleLineLimit: Int {
        switch self {
            case .podcast, .latest, .collection: 3
            case .grid, .featured: 2
        }
    }
    var descriptionLineLimit: Int {
        switch self {
            case .podcast: 2
            case .latest, .collection: 1
            case .grid, .featured: 1
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
#Preview("Podcast") {
    NavigationStack {
        List {
            EpisodeList(episodes: [.fixture, .fixture, .fixture], context: .podcast, selected: .constant(nil))
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}

#Preview("Latest") {
    NavigationStack {
        List {
            EpisodeList(episodes: [.fixture, .fixture, .fixture], context: .latest, selected: .constant(nil))
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}

#Preview("Collection") {
    NavigationStack {
        List {
            EpisodeList(episodes: [.fixture, .fixture, .fixture], context: .collection, selected: .constant(nil))
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}

#Preview("Featured") {
    NavigationStack {
        List {
            EpisodeList(episodes: [.fixture], context: .featured, selected: .constant(nil))
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}

#Preview("Grid") {
    NavigationStack {
        EpisodeGrid(episodes: [.fixture, .fixture, .fixture, .fixture])
    }
    .previewEnvironment()
}

#Preview("Bulk select") {
    NavigationStack {
        List {
            EpisodeList(episodes: [.fixture, .fixture, .fixture], context: .podcast, selected: .constant([]))
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}
#endif
