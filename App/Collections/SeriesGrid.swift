//
//  SeriesGrid.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

struct SeriesGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let series: [Series]
    let showName: Bool
    let onAppear: ((_: Series) -> Void)

    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 112.0 : 120.0
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 12)], spacing: 12) {
            ForEach(series) { item in
                NavigationLink(value: NavigationDestination.item(item)) {
                    SeriesGridItem(series: item, showName: showName)
                        .padding(8)
                        .universalContentShape(.rect(cornerRadius: 8))
                }
                .buttonStyle(.plain)
                .modifier(ItemStatusModifier(item: item))
                .padding(-8)
                .onAppear {
                    onAppear(item)
                }
            }
        }
    }
}

struct SeriesHGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let series: [Series]

    @State private var width: CGFloat = .zero

    private let gap: CGFloat = 12
    private let padding: CGFloat = 20

    // Mirrors `AudiobookHGrid` so the row visually matches an audiobook row.
    private var minimumSize: CGFloat {
        horizontalSizeClass == .compact ? 100.0 : 120.0
    }
    private var size: CGFloat {
        guard width.isFinite, width > padding * 2 else { return minimumSize }

        let usable = width - padding * 2
        let paddedSize = minimumSize + gap

        let amount = CGFloat(Int(usable / paddedSize))
        guard amount > 0 else { return minimumSize }

        let available = usable - gap * (amount - 1)
        return max(minimumSize, available / amount)
    }

    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) {
                        width = proxy.size.width
                    }
            }
            .frame(height: 0)

            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(alignment: .top, spacing: gap) {
                    ForEach(series) { item in
                        NavigationLink(value: NavigationDestination.item(item)) {
                            SeriesGrid.SeriesGridItem(series: item, showName: true)
                                .frame(width: size)
                        }
                        .buttonStyle(.plain)
                        .modifier(ItemStatusModifier(item: item))
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, padding)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

extension SeriesGrid {
    struct SeriesGridItem: View {
        let name: String?
        let audiobookIDs: [ItemIdentifier]

        init(series: Series, showName: Bool) {
            self.name = showName ? series.name : nil
            self.audiobookIDs = series.audiobooks.map(\.id)
        }

        init(name: String?, audiobookIDs: [ItemIdentifier]) {
            self.name = name
            self.audiobookIDs = audiobookIDs
        }

        private var spacing: CGFloat {
            4
        }
        private var flipped: Bool {
            audiobookIDs.count == 3
        }

        var body: some View {
            VStack(spacing: 4) {
                Group {
                    if audiobookIDs.isEmpty {
                        ItemImage(item: nil, size: .small)
                    } else if audiobookIDs.count == 1 {
                        ItemImage(itemID: audiobookIDs.first, size: .small)
                    } else if audiobookIDs.count < 4 {
                        GeometryReader { proxy in
                            let width = proxy.size.width / 1.6

                            ZStack(alignment: flipped ? .bottomLeading : .topLeading) {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)

                                Group {
                                    ItemImage(itemID: audiobookIDs[0], size: .tiny)
                                    ItemImage(itemID: audiobookIDs[1], size: .tiny)
                                        .offset(x: proxy.size.width - width, y: (proxy.size.height - width) * (flipped ? -1 : 1))
                                }
                                .frame(width: width)
                            }
                        }
                        .aspectRatio(1, contentMode: .fill)
                    } else {
                        VStack(spacing: spacing) {
                            HStack(spacing: spacing) {
                                ItemImage(itemID: audiobookIDs[0], size: .tiny)
                                ItemImage(itemID: audiobookIDs[1], size: .tiny)
                            }
                            HStack(spacing: spacing) {
                                ItemImage(itemID: audiobookIDs[2], size: .tiny)
                                ItemImage(itemID: audiobookIDs[3], size: .tiny)
                            }
                        }
                    }
                }

                if let name {
                    Text(name)
                        .font(.caption)
                        .lineLimit(1)
                }
            }
        }
    }
}
