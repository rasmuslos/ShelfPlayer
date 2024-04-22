//
//  AudiobookGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPPlayback

struct AudiobookVGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let audiobooks: [Audiobook]
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 160.0 : 200.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 15)], spacing: 20) {
            ForEach(audiobooks) { audiobook in
                NavigationLink {
                    AudiobookView(audiobook: audiobook)
                } label: {
                    ItemStatusImage(item: audiobook)
                        .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
                }
                .buttonStyle(.plain)
            }
        }
    }
}

struct AudiobookHGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let audiobooks: [Audiobook]
    var small = false
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = 10
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
        let minimum = horizontalSizeClass == .compact ? small ? 90.0 : 120.0 : small ? 120.0 : 200.0
        
        let usable = width - padding * 2
        let amount = CGFloat(Int(usable / minimum))
        let available = usable - gap * (amount - 1)
        
        return max(minimum, available / amount)
    }
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onAppear {
                        width = proxy.size.width
                    }
                    .onChange(of: proxy.size.width) {
                        width = proxy.size.width
                    }
            }
            .frame(height: 0)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(audiobooks) { audiobook in
                        NavigationLink(destination: AudiobookView(audiobook: audiobook)) {
                            ItemStatusImage(item: audiobook)
                                .frame(width: size)
                                .padding(.leading, gap)
                                .modifier(AudiobookContextMenuModifier(audiobook: audiobook))
                        }
                        .buttonStyle(.plain)
                    }
                }
                .scrollTargetLayout()
                .padding(.leading, gap)
                .padding(.trailing, padding)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            AudiobookVGrid(audiobooks: [
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
            ])
        }
    }
}

#Preview {
    NavigationStack {
        ScrollView {
            AudiobookHGrid(audiobooks: [
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
                Audiobook.fixture,
            ])
        }
    }
}

