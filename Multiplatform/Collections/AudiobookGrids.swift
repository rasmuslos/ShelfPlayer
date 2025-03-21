//
//  AudiobookGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

struct AudiobookVGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let sections: [AudiobookSection]
    let onAppear: ((_: AudiobookSection) -> Void)
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 100.0 : 200.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 16)], spacing: 16) {
            ForEach(sections) { section in
                VStack(spacing: 0) {
                    switch section {
                    case .audiobook(let audiobook):
                        NavigationLink {
                            AudiobookView(audiobook)
                        } label: {
                            ItemProgressIndicatorImage(itemID: audiobook.id, size: .small, aspectRatio: .none)
                                .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
                                .hoverEffect(.highlight)
                        }
                    case .series(let seriesID, _, let audiobookIDs):
                        NavigationLink(destination: ItemLoadView(seriesID)) {
                            SeriesGrid.SeriesGridItem(name: nil, audiobookIDs: audiobookIDs)
                        }
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
    
    private let gap: CGFloat = 8
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
        let usable = width - padding * 2
        let paddedSize = minimumSize + gap
        
        let amount = CGFloat(Int(usable / paddedSize))
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
                LazyHStack(alignment: .bottom, spacing: 0) {
                    ForEach(audiobooks) { audiobook in
                        NavigationLink(destination: AudiobookView(audiobook)) {
                            ItemProgressIndicatorImage(itemID: audiobook.id, size: .small, aspectRatio: .none)
                                .frame(width: size)
                                .padding(.leading, gap)
                                .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
                                .hoverEffect(.highlight)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                .padding(.leading, 20 - gap)
                .padding(.trailing, padding)
            }
            .scrollTargetBehavior(.viewAligned)
            .scrollClipDisabled()
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            AudiobookVGrid(sections: .init(repeating: .audiobook(audiobook: .fixture), count: 7)) { _ in }
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            AudiobookHGrid(audiobooks: .init(repeating: .fixture, count: 77), small: true)
        }
    }
}
#endif
