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
        @Environment(EpisodeViewModel.self) private var viewModel

        var body: some View {
            @Bindable var viewModel = viewModel

            VStack(alignment: .leading, spacing: 0) {
                HeroBackground(threshold: -60, backgroundColor: .clear, isToolbarVisible: $viewModel.toolbarVisible)
                    .frame(height: 0)

                HStack(spacing: 6) {
                    if let releaseDate = viewModel.episode.releaseDate {
                        if Calendar.current.component(.year, from: releaseDate) == Calendar.current.component(.year, from: .now) {
                            Text(releaseDate, format: .dateTime.day().month(.wide))
                        } else {
                            Text(releaseDate, format: .dateTime.day().month(.wide).year())
                        }
                    }

                    if viewModel.episode.type == .trailer {
                        Text("·")
                        Text("item.trailer")
                        Image(systemName: "movieclapper.fill")
                    } else if viewModel.episode.type == .bonus {
                        Text("·")
                        Text("item.bonus")
                        Image(systemName: "fireworks")
                    }
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                Text(viewModel.episode.name)
                    .font(.title2.bold())
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)

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
                .padding(.top, 8)

                HStack(spacing: 20) {
                    EpisodePlayButton(episode: viewModel.episode)

                    QueueButton(itemID: viewModel.episode.id, short: true)

                    DownloadButton(itemID: viewModel.episode.id, progressVisibility: .toolbar)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.plain)
                .foregroundStyle(.secondary)
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }
}
