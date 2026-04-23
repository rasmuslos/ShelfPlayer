//
//  PlaybackBottomBarPill.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 14.09.25.
//

import SwiftUI
import ShelfPlayback

@available(iOS 26.0, *)
struct PlaybackBottomBarPill: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    @Environment(\.namespace) private var namespace
    @Environment(\.tabViewBottomAccessoryPlacement) private var accessoryPlacement

    var decorative = false

    @State private var marqueeController = MarqueeController()

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
        ItemImage(itemID: satellite.nowPlayingItemID, size: .small, cornerRadius: viewModel.PILL_IMAGE_CORNER_RADIUS)
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
            .padding(.vertical, 8)
            .id((satellite.nowPlayingItemID?.description ?? "qkwndoiqind") + "_nowPlaying_image_collapsed")

            VStack(alignment: .leading, spacing: 0) {
                MarqueeText(text: itemName, font: .subheadline, controller: marqueeController)

                if !itemSubtitle.isEmpty {
                    MarqueeText(text: itemSubtitle.joined(separator: " • "), font: .caption, foregroundStyle: .init(.secondary), controller: marqueeController)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .id((satellite.nowPlayingItem?.name ?? "wngrwghrgg") + "_nowPlaying_collapsed_name")

            if viewModel.isPillBackButtonVisible {
                PlaybackBackwardButton()
                    .bold()
                    .frame(width: 24)
            }

            PlaybackSmallTogglePlayButton()
                .font(.title3)
                .frame(width: 24)
        }
        .contentShape(.rect)
        .font(.subheadline)
        .padding(.horizontal, 16)
        .id((satellite.nowPlayingItemID?.description ?? "wejjfnwioejf") + "_nowPlaying_bottom_pill")
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
                        .opacity(viewModel.showCompactPlaybackBarOnExpandedViewCount > 0 ? 0 : 1)
                }
                .buttonStyle(.plain)
                .simultaneousGesture(
                    DragGesture(minimumDistance: 10)
                        .onEnded { value in
                            guard !viewModel.isExpanded else { return }
                            if value.translation.height < -20 || value.velocity.height < -500 {
                                viewModel.toggleExpanded()
                            }
                        }
                )
                .onChange(of: x, initial: true) { viewModel.pillX = x }
                .onChange(of: y, initial: true) { viewModel.pillY = y }
                .onChange(of: width, initial: true) { viewModel.pillWidth = width }
                .onChange(of: height, initial: true) { viewModel.pillHeight = height }
                .onChange(of: accessoryPlacement, initial: true) { viewModel.isPillBackButtonVisible = accessoryPlacement == .expanded }
                .task {
                    viewModel.isUsingLegacyPillDesign = false
                }
                .contextMenu {
                    PlaybackMenuActions()
                } preview: {
                    if let currentItem = satellite.nowPlayingItem {
                        PlayableItemContextMenuPreview(item: currentItem)
                    }
                }
            }
            .id((satellite.nowPlayingItem?.name ?? "wngrwghrgg") + "_nowPlaying_collapsed")
        }
    }
}

#if DEBUG
#Preview {
    if #available(iOS 26.0, *) {
        TabView {
            ForEach(["Tab 1", "Tab 2", "Tab 3"].enumerated(), id: \.offset) { (index, tab) in
                Tab(tab, systemImage: "command") {
                    ScrollView {
                        ForEach(0..<100) { _ in
                            Rectangle()
                                .fill(.blue)
                                .frame(height: 400)
                        }
                    }
                    .ignoresSafeArea()
                }
                .badge(index)
            }

            Tab(role: .search) {

            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            PlaybackBottomBarPill()
        }
        .previewEnvironment()
    } else {
        Text(verbatim: ":(")
    }
}
#endif
