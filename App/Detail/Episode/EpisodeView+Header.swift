//
//  EpisodeView+Header.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

extension EpisodeView {
    struct Header: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(EpisodeViewModel.self) private var viewModel

        var body: some View {
            @Bindable var viewModel = viewModel

            ZStack(alignment: .top) {
                HeroBackground(threshold: horizontalSizeClass == .regular ? -90 : -60, backgroundColor: .clear, isToolbarVisible: $viewModel.toolbarVisible)
                    .frame(height: 0)

                ViewThatFits {
                    RegularPresentation()
                    CompactPresentation()
                }
            }
        }
    }
}

private struct ReleaseLine: View {
    @Environment(EpisodeViewModel.self) private var viewModel

    var body: some View {
        HStack(spacing: 6) {
            if let releaseDate = viewModel.episode.releaseDate {
                if Calendar.current.component(.year, from: releaseDate) == Calendar.current.component(.year, from: .now) {
                    Text(releaseDate, format: .dateTime.day().month(.wide))
                } else {
                    Text(releaseDate, format: .dateTime.day().month(.wide).year())
                }
            }

            if viewModel.episode.type == .trailer {
                Text(verbatim: "•")
                Text("item.trailer")
                Image(systemName: "movieclapper.fill")
            } else if viewModel.episode.type == .bonus {
                Text(verbatim: "•")
                Text("item.bonus")
                Image(systemName: "fireworks")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }
}

private struct PodcastLink: View {
    @Environment(EpisodeViewModel.self) private var viewModel

    var body: some View {
        NavigationLink(value: NavigationDestination.itemID(viewModel.episode.podcastID)) {
            HStack(spacing: 6) {
                ItemImage(itemID: viewModel.episode.podcastID, size: .small, cornerRadius: 4, contrastConfiguration: nil)
                    .frame(width: 28)

                Text(viewModel.episode.podcastName)
                    .lineLimit(1)

                Image(systemName: "chevron.right")
                    .font(.caption2)
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
        .hoverEffect()
    }
}

private struct ActionRow: View {
    @Environment(EpisodeViewModel.self) private var viewModel

    var body: some View {
        HStack(spacing: 12) {
            PlayButton(item: viewModel.episode)
                .playButtonSize(.compact)

            HeaderActionButton {
                QueueButton(itemID: viewModel.episode.id, short: true)
                    .labelStyle(.iconOnly)
            }

            HeaderActionButton {
                DownloadButton(itemID: viewModel.episode.id, progressVisibility: .toolbar)
                    .labelStyle(.iconOnly)
            }
        }
    }
}

private struct CompactPresentation: View {
    @Environment(EpisodeViewModel.self) private var viewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ReleaseLine()

            Text(viewModel.episode.name)
                .font(.title2.bold())
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            PodcastLink()
                .padding(.top, 8)

            ActionRow()
                .padding(.top, 12)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }
}

private struct RegularPresentation: View {
    @Environment(EpisodeViewModel.self) private var viewModel

    var body: some View {
        HStack(alignment: .top, spacing: 32) {
            ItemImage(item: viewModel.episode, size: .large, contrastConfiguration: .init(shadowRadius: 16, shadowOpacity: 0.25))
                .frame(width: 256, height: 256)

            VStack(alignment: .leading, spacing: 8) {
                ReleaseLine()

                Text(viewModel.episode.name)
                    .font(.largeTitle.bold())
                    .lineLimit(4)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.trailing, 16)

                PodcastLink()
                    .padding(.top, 4)

                Spacer(minLength: 0)

                ActionRow()
                    .padding(.top, 8)
            }
            .frame(minWidth: 240, maxWidth: 560, alignment: .leading)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: 1000)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 20)
        .padding(.top, 12)
    }
}
