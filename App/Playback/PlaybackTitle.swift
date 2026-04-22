//
//  PlaybackTitle.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 26.02.25.
//

import SwiftUI
import ShelfPlayback

struct PlaybackTitle: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    let showTertiarySupplements: Bool

    @State private var uuid = UUID()
    @State private var marqueeController = MarqueeController()

    var body: some View {
        HStack(spacing: 0) {
            Menu {
                PlaybackMenuActions()
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    if let currentItem = satellite.nowPlayingItem {
                        if showTertiarySupplements, let episode = currentItem as? Episode, let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                                .font(.subheadline.smallCaps())
                                .foregroundStyle(.tertiary)
                        }

                        MarqueeText(text: currentItem.name, font: .headline, controller: marqueeController)
                            .id(currentItem.name)

                        MarqueeText(text: currentItem.authors.formatted(.list(type: .and, width: .short)), font: .subheadline, foregroundStyle: .init(.secondary), controller: marqueeController)
                            .id(currentItem.authors)
                    } else {
                        Text("loading")
                            .font(.headline)
                    }
                }
                .id((satellite.nowPlayingItem?.sortName ?? "ijwefnoijoiujoizg") + "_nowPlaying_text_title_\(uuid)")
                .contentShape(.rect)
            }
            .buttonStyle(.plain)

            if satellite.nowPlayingItemID?.type == .audiobook {
                Spacer(minLength: 12)

                if viewModel.isCreatingBookmark {
                    ProgressView()
                } else {
                    Label("playback.alert.createBookmark", systemImage: "bookmark")
                        .labelStyle(.iconOnly)
                        .padding(4)
                        .contentShape(.rect)
                        .onTapGesture {
                            viewModel.presentCreateBookmarkAlert()
                        }
                        .onLongPressGesture {
                            viewModel.createQuickBookmark()
                        }
                }
            } else {
                Spacer(minLength: 0)
            }
        }
    }
}

struct PlaybackMenuActions: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite

    var body: some View {
        if let currentItem = satellite.nowPlayingItem {
            ControlGroup {
                ProgressButton(itemID: currentItem.id)
                StopPlaybackButton()

                ItemCollectionMembershipEditButton(itemID: currentItem.id)
            }

            if let audiobook = currentItem as? Audiobook {
                ItemLoadLink(itemID: audiobook.id)
                ItemMenu(authors: viewModel.authorIDs)
                ItemMenu(narrators: viewModel.narratorIDs)
                ItemMenu(series: viewModel.seriesIDs)
            } else if let episode = currentItem as? Episode {
                ItemLoadLink(itemID: episode.id)
                ItemLoadLink(itemID: episode.podcastID)
            }

            if let collection = satellite.upNextOrigin as? ItemCollection {
                ItemLoadLink(itemID: collection.id, footer: collection.name)
            }
        }
    }
}

private struct StopPlaybackButton: View {
    @Environment(Satellite.self) private var satellite

    var body: some View {
        Button("playback.stop", systemImage: "stop.fill") {
            satellite.stop()
        }
    }
}

#if DEBUG
#Preview {
    PlaybackTitle(showTertiarySupplements: true)
        .previewEnvironment()
}
#endif
