//
//  CompactLegacyCollapsedForeground.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 16.09.25.
//

import SwiftUI
import ShelfPlayback

/// Height of the collapsed legacy pill. Kept snug so the artwork fills most of
/// the bar — shared with the placeholder variant so both line up.
private let legacyCollapsedPillHeight: CGFloat = 52

/// Background chrome for the collapsed legacy pill: a glass capsule on iOS 26,
/// a translucent shadowed bar on earlier releases.
private struct LegacyPillChrome: ViewModifier {
    @Environment(PlaybackViewModel.self) private var viewModel

    func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            content
                .glassEffect()
        } else {
            content
                .background(.bar, in: .rect(cornerRadius: viewModel.PILL_CORNER_RADIUS))
                .shadow(color: .black.opacity(0.2), radius: 12)
        }
    }
}

struct CompactLegacyCollapsedForeground: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    let decorative: Bool

    @State private var marqueeController = MarqueeController()

    var horizontalPadding: CGFloat {
        if #available(iOS 26, *) {
            8
        } else {
            12
        }
    }

    private var itemName: String {
        if let chapter = satellite.chapter, satellite.nowPlayingItemID?.type == .audiobook {
            chapter.title
        } else {
            satellite.nowPlayingItem?.name ?? String(localized: "loading")
        }
    }
    private var itemSubtitle: [String] {
        var parts = [String]()

        if let audiobook = satellite.nowPlayingItem as? Audiobook {
            parts.append(audiobook.name)

            if !audiobook.authors.isEmpty {
                parts.append(audiobook.authors.formatted(.list(type: .and, width: .narrow)))
            }
        } else if let episode = satellite.nowPlayingItem as? Episode {
            parts.append(episode.podcastName)

            if let releaseDate = episode.releaseDate {
                parts.append(releaseDate.formatted(date: .abbreviated, time: .omitted))
            }
            if let chapter = satellite.chapter {
                parts.append(chapter.title)
            }
        }

        return parts
    }

    @ViewBuilder
    private var image: some View {
        ItemImage(itemID: satellite.nowPlayingItemID, size: .small, cornerRadius: viewModel.PILL_IMAGE_CORNER_RADIUS, aspectRatio: .none)
            .opacity(!viewModel.isExpanded && viewModel.expansionAnimationCount <= 0 ? 1 : 0)
    }

    @ViewBuilder
    private var label: some View {
        HStack(spacing: 8) {
            GeometryReader { imageGeometryProxy in
                let x = imageGeometryProxy.frame(in: .global).minX
                let y = imageGeometryProxy.frame(in: .global).minY

                let size = imageGeometryProxy.size.width

                if !decorative {
                    Rectangle()
                        .fill(.clear)
                        .onChange(of: x, initial: true) { viewModel.pillImageX = x }
                        .onChange(of: y, initial: true) { viewModel.pillImageY = y }
                        .onChange(of: size, initial: true) { viewModel.pillImageSize = size }

                    Color.clear
                        .overlay {
                            image
                        }
                } else {
                    image
                }
            }
            .aspectRatio(1, contentMode: .fit)
            .padding(.vertical, 6)
            .id((satellite.nowPlayingItemID?.description ?? "placeholder") + "_nowPlaying_image_compact_legacy")

            VStack(alignment: .leading, spacing: 0) {
                MarqueeText(text: itemName, font: .subheadline, controller: marqueeController)

                if !itemSubtitle.isEmpty {
                    MarqueeText(text: itemSubtitle.joined(separator: " • "), font: .caption, foregroundStyle: .init(.secondary), controller: marqueeController)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .id((satellite.nowPlayingItem?.sortName ?? "placeholder") + "_nowPlaying_text_legacy_compact")

            PlaybackBackwardButton()
                .bold()
                .frame(width: 24)

            PlaybackSmallTogglePlayButton()
                .font(.title3)
                .frame(width: 24)
        }
        .contentShape(.rect)
        .padding(.horizontal, 16)
        .modify(if: !decorative) {
            $0.modifier(LegacyPillChrome())
        }
    }

    var body: some View {
        if decorative {
            label
        } else {
            GeometryReader { geometryProxy in
                let x = geometryProxy.frame(in: .global).minX
                let y = geometryProxy.frame(in: .global).minY

                let width = geometryProxy.frame(in: .global).width
                let height = geometryProxy.frame(in: .global).height


                Button {
                    viewModel.toggleExpanded()
                } label: {
                    label
                }
                .buttonStyle(.plain)
                .universalContentShape(RoundedRectangle(cornerRadius: viewModel.PILL_CORNER_RADIUS, style: .continuous))
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { value in
                            guard !viewModel.isExpanded else { return }
                            if value.translation.height < -20 || value.velocity.height < -500 {
                                viewModel.toggleExpanded()
                            }
                        }
                )
                .contextMenu {
                    PlaybackMenuActions()
                } preview: {
                    if let currentItem = satellite.nowPlayingItem {
                        PlayableItemContextMenuPreview(item: currentItem)
                    }
                }
                .onChange(of: x, initial: true) { viewModel.pillX = x }
                .onChange(of: y, initial: true) { viewModel.pillY = y }
                .onChange(of: width, initial: true) { viewModel.pillWidth = width }
                .onChange(of: height, initial: true) { viewModel.pillHeight = height }
                .task {
                    viewModel.isUsingLegacyPillDesign = true
                }
            }
            .frame(height: legacyCollapsedPillHeight)
            .padding(.horizontal, horizontalPadding)
        }
    }
}

/// Legacy counterpart to `PlaybackPlaceholderBottomPill`, shown when nothing is
/// playing but a previously played item can be resumed. Wraps the shared
/// placeholder content in the same chrome and footprint as the collapsed pill.
struct CompactLegacyPlaceholderForeground: View {
    @Environment(OfflineMode.self) private var offlineMode

    let itemID: ItemIdentifier

    @State private var download: DownloadStatusTracker

    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        _download = State(initialValue: DownloadStatusTracker(itemID: itemID))
    }

    var horizontalPadding: CGFloat {
        if #available(iOS 26, *) {
            8
        } else {
            12
        }
    }

    /// Offline, the item can only be resumed when it is downloaded, so suppress
    /// the placeholder for items that aren't available locally.
    private var isVisible: Bool {
        !offlineMode.isEnabled || download.status == .completed
    }

    var body: some View {
        if isVisible {
            PlaybackPlaceholderBottomPill(itemID: itemID)
                .modifier(LegacyPillChrome())
                .frame(height: legacyCollapsedPillHeight)
                .padding(.horizontal, horizontalPadding)
        }
    }
}

struct ApplyLegacyCollapsedForeground: ViewModifier {
    @Environment(\.playbackBottomSafeArea) private var playbackBottomSafeArea
    @Environment(\.playbackBottomOffset) private var playbackBottomOffset

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @Environment(Satellite.self) private var satellite

    @Bindable private var settings = AppSettings.shared

    var isEnabled = true

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if isEnabled, horizontalSizeClass == .compact {
                    Group {
                        if satellite.nowPlayingItemID != nil {
                            CompactLegacyCollapsedForeground(decorative: false)
                        } else if let lastPlayedItemID = settings.lastPlayedItemID {
                            CompactLegacyPlaceholderForeground(itemID: lastPlayedItemID)
                                .id(lastPlayedItemID)
                        }
                    }
                    .offset(y: -(playbackBottomOffset + playbackBottomSafeArea))
                }
            }
    }
}
