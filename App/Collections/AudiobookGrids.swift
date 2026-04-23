//
//  AudiobookGrids.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayback

struct AudiobookVGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    let sections: [AudiobookSection]
    let onAppear: ((_: AudiobookSection) -> Void)

    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 100.0 : 120.0
    }

    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 12)], spacing: 12) {
            ForEach(sections) { section in
                VStack(spacing: 0) {
                    switch section {
                        case .audiobook(let audiobook):
                            NavigationLink(value: NavigationDestination.item(audiobook)) {
                                ItemProgressIndicatorImage(itemID: audiobook.id, size: .small, aspectRatio: .none, fallbackLabel: audiobook.name)
                            }
                            .buttonStyle(.plain)
                            .modifier(ItemStatusModifier(item: audiobook))
                        case .series(let seriesID, _, let audiobookIDs):
                            NavigationLink(value: NavigationDestination.itemID(seriesID)) {
                                SeriesGrid.SeriesGridItem(name: nil, audiobookIDs: audiobookIDs)
                            }
                            .buttonStyle(.plain)
                            .modifier(ItemStatusModifier(itemID: seriesID))
                    }

                    Spacer(minLength: 0)
                }
                .buttonStyle(.plain)
                .onAppear {
                    onAppear(section)
                }
            }
        }
    }
}

struct AudiobookHGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private let gap: CGFloat = 12
    private let padding: CGFloat = 20

    let audiobooks: [Audiobook]
    let small: Bool

    @State private var width: CGFloat = .zero

    private var minimumSize: CGFloat {
        if horizontalSizeClass == .compact {
            small ? 80.0 : 100.0
        } else {
            small ? 100.0 : 120.0
        }
    }
    private var size: CGFloat {
        // Guard against the initial GeometryReader measurement (width = 0) and
        // any transient pass where the proposal would yield a non-positive
        // column count. Returning a NaN here via `-28 / 0` poisons the layout
        // engine and causes a UICollectionView recursive layout loop.
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
                LazyHStack(alignment: .bottom, spacing: gap) {
                    ForEach(audiobooks) { audiobook in
                        NavigationLink(value: NavigationDestination.item(audiobook)) {
                            ItemProgressIndicatorImage(itemID: audiobook.id, size: .small, aspectRatio: .none, fallbackLabel: audiobook.name)
                                .frame(width: size)
                        }
                        .buttonStyle(.plain)
                        .modifier(ItemStatusModifier(item: audiobook))
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, 20)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}
