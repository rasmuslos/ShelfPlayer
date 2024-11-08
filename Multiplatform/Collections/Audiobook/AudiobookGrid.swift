//
//  AudiobookGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPFoundation
import SPOffline
import SPPlayback

internal struct AudiobookVGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let sections: [AudiobookSection]
    var onAppear: ((_ section: AudiobookSection) -> Void)? = nil
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 100.0 : 200.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 16)], spacing: 16) {
            ForEach(sections, id: \.self) { section in
                VStack(spacing: 0) {
                    switch section {
                    case .audiobook(let audiobook):
                        NavigationLink {
                            AudiobookView(audiobook)
                        } label: {
                            ItemStatusImage(item: audiobook, aspectRatio: .none)
                                .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
                                .hoverEffect(.highlight)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            onAppear?(section)
                        }
                    case .series(let seriesName, let audiobooks):
                        NavigationLink(destination: SeriesLoadView(seriesName: seriesName)) {
                            SeriesGrid.SeriesGridItem(name: nil, covers: audiobooks.prefix(10).compactMap { $0.cover })
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            onAppear?(section)
                        }
                    }
                    
                    Spacer()
                }
            }
        }
    }
}

internal struct AudiobookHGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let audiobooks: [Audiobook]
    var small = false
    
    @State private var width: CGFloat = .zero
    
    private var gap: CGFloat { small ? 8 : 12 }
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
        let minimum = horizontalSizeClass == .compact ? small ? 90.0 : 120.0 : small ? 120.0 : 160.0
        
        let usable = width - padding * 2
        let amount = CGFloat(Int(usable / minimum))
        let available = usable - gap * (amount - 1)
        
        return max(minimum, available / amount)
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
                HStack(alignment: .bottom, spacing: 0) {
                    ForEach(audiobooks) { audiobook in
                        NavigationLink(destination: AudiobookView(audiobook)) {
                            ItemStatusImage(item: audiobook, aspectRatio: .none)
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
            AudiobookVGrid(sections: .init(repeating: [.audiobook(audiobook: .fixture)], count: 7))
        }
        .padding(.horizontal, 20)
    }
    .environment(NowPlaying.ViewModel())
}

#Preview {
    NavigationStack {
        ScrollView {
            AudiobookHGrid(audiobooks: .init(repeating: [.fixture], count: 7), small: true)
        }
    }
    .environment(NowPlaying.ViewModel())
}
#endif
