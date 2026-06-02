//
//  ChannelGrid.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.26.
//

import SwiftUI
import ShelfPlayback

struct ChannelVGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let channels: [Channel]

    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 100.0 : 140.0
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 200), spacing: 16)], alignment: .center, spacing: 20) {
            ForEach(channels) { channel in
                NavigationLink(value: NavigationDestination.item(channel)) {
                    VStack(spacing: 4) {
                        ItemImage(item: channel, size: .small, cornerRadius: 12)

                        Text(channel.name)
                            .font(.caption)
                            .lineLimit(1)

                        Text("item.count.podcasts \(channel.podcasts.count)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    .universalContentShape(.rect(cornerRadius: 8))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct ChannelList: View {
    let channels: [Channel]

    var body: some View {
        ForEach(channels) { channel in
            NavigationLink(value: NavigationDestination.item(channel)) {
                HStack(spacing: 12) {
                    ItemImage(item: channel, size: .small, cornerRadius: 8)
                        .frame(width: 48, height: 48)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(channel.name)
                            .lineLimit(1)

                        Text("item.count.podcasts \(channel.podcasts.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            }
            .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
        }
    }
}
