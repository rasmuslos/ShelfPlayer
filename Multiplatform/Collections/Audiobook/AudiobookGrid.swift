//
//  AudiobookGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPFoundation
import SPPersistence
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
            ForEach(sections) { section in
                VStack(spacing: 0) {
                    switch section {
                    case .audiobook(let audiobook):
                        NavigationLink {
                            AudiobookView(audiobook)
                        } label: {
                            ItemProgressIndicatorImage(item: audiobook, aspectRatio: .none)
                                .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
                                .hoverEffect(.highlight)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            onAppear?(section)
                        }
                    case .series(let seriesID, _, let audiobookIDs):
                        NavigationLink(destination: ItemLoadView(seriesID)) {
                            SeriesGrid.SeriesGridItem(name: nil, audiobookIDs: audiobookIDs)
                        }
                        .buttonStyle(.plain)
                        .onAppear {
                            onAppear?(section)
                        }
                    }
                    
                    Spacer(minLength: 0)
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
    
    private let gap: CGFloat = 8
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
                            ItemProgressIndicatorImage(item: audiobook, aspectRatio: .none)
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
            AudiobookVGrid(sections: .init(repeating: .audiobook(audiobook: .fixture), count: 7))
        }
        .padding(.horizontal, 20)
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            AudiobookHGrid(audiobooks: .init(repeating: .fixture, count: 7), small: true)
        }
    }
}
#endif
