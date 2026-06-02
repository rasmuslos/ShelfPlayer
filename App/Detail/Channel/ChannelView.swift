//
//  ChannelView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.26.
//

import SwiftUI
import ShelfPlayback

struct ChannelView: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let channel: Channel

    @State private var displayType: ItemDisplayType = AppSettings.shared.podcastsDisplayType
    @State private var isToolbarVisible = false

    init(_ channel: Channel) {
        self.channel = channel
    }

    private var isRegular: Bool {
        horizontalSizeClass == .regular
    }

    @ViewBuilder
    private func header(topInset: CGFloat) -> some View {
        ZStack(alignment: .topLeading) {
            HeroBackground(threshold: isRegular ? -60 : -40, backgroundColor: nil, isToolbarVisible: $isToolbarVisible)

            HStack(spacing: 12) {
                ItemImage(item: channel, size: .small, contrastConfiguration: nil)
                    .frame(width: 56, height: 56)

                VStack(alignment: .leading, spacing: 2) {
                    Text(channel.name)
                        .font(.headline)
                        .lineLimit(2)

                    Text("item.count.podcasts \(channel.podcasts.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            // `topInset` already accounts for the status bar + navigation bar, so
            // the header clears the bar on every device without a magic number.
            .padding(.top, topInset + 8)
            .padding(.bottom, 8)
        }
    }

    var body: some View {
        GeometryReader { proxy in
            let topInset = proxy.safeAreaInsets.top

            Group {
                if channel.podcasts.isEmpty {
                    EmptyCollectionView()
                } else {
                    switch displayType {
                    case .grid:
                        ScrollView {
                            header(topInset: topInset)

                            PodcastVGrid(podcasts: channel.podcasts) { _ in }
                                .padding(.horizontal, 20)
                        }
                    case .list:
                        List {
                            header(topInset: topInset)
                                .listRowSeparator(.hidden)
                                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))

                            PodcastList(podcasts: channel.podcasts) { _ in }
                        }
                        .listStyle(.plain)
                    }
                }
            }
            .ignoresSafeArea(edges: .top)
        }
        .navigationTitle(channel.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(isRegular ? .automatic : isToolbarVisible ? .visible : .hidden, for: .navigationBar)
        .navigationBarBackButtonHidden(!isToolbarVisible && !isRegular)
        .toolbar {
            ToolbarItem(placement: .principal) {
                if isToolbarVisible {
                    Text(channel.name)
                        .font(.headline)
                        .lineLimit(1)
                } else {
                    Text(verbatim: "")
                }
            }

            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "line.3.horizontal") {
                    ItemDisplayTypePicker(displayType: $displayType)
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .toolbar {
            if !isToolbarVisible && !isRegular {
                ToolbarItem(placement: .navigation) {
                    HeroBackButton()
                }
            }
        }
        .onChange(of: displayType) {
            AppSettings.shared.podcastsDisplayType = displayType
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .userActivity("io.rfk.shelfPlayer.item") { activity in
            activity.title = channel.name
            activity.isEligibleForHandoff = true
            activity.isEligibleForPrediction = true
            activity.persistentIdentifier = channel.id.description

            Task {
                try await activity.webpageURL = channel.id.url
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ChannelView(.fixture)
    }
    .previewEnvironment()
}

#Preview("Multiline") {
    let name = "Norddeutscher Rundfunk Kultur Redaktion Abteilung Wirtschaft und Verfassungsrecht Sektion Visuelle Kommunikation"

    NavigationStack {
        ChannelView(Channel(
            id: Channel.convertNameToID(name, libraryID: "fixture", connectionID: "fixture"),
            name: name,
            podcasts: .init(repeating: .fixture, count: 5)))
    }
    .previewEnvironment()
}
#endif
