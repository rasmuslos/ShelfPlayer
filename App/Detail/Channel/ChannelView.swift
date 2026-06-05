//
//  ChannelView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.26.
//

import SwiftUI
import ShelfPlayback

struct ChannelView: View {
    let channel: Channel

    @State private var displayType: ItemDisplayType = AppSettings.shared.podcastsDisplayType

    init(_ channel: Channel) {
        self.channel = channel
    }

    var body: some View {
        Group {
            if channel.podcasts.isEmpty {
                EmptyCollectionView()
            } else {
                switch displayType {
                case .grid:
                    ScrollView {
                        PodcastVGrid(podcasts: channel.podcasts) { _ in }
                            .padding(.horizontal, 20)
                    }
                case .list:
                    List {
                        PodcastList(podcasts: channel.podcasts) { _ in }
                    }
                    .listStyle(.plain)
                }
            }
        }
        .navigationTitle(channel.name)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "line.3.horizontal") {
                    ItemDisplayTypePicker(displayType: $displayType)
                }
                .menuActionDismissBehavior(.disabled)
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
