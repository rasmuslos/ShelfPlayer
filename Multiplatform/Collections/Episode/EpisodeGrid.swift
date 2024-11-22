//
//  EpisodeTable.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation

internal struct EpisodeGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let episodes: [Episode]
    var amount = 2
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = 12
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
        let minimum = horizontalSizeClass == .compact ? 300 : 450.0
        
        let usable = width - (padding + gap)
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
                LazyHGrid(rows: [GridItem(.flexible(), spacing: 8)].repeated(count: amount), spacing: 0) {
                    EpisodeList(episodes: episodes, zoom: true)
                        .padding(.leading, gap)
                        .frame(width: size)
                }
                .scrollTargetLayout()
                .padding(.leading, 20 - gap)
                .padding(.trailing, padding)
            }
            .scrollTargetBehavior(.viewAligned)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        EpisodeGrid(episodes: .init(repeating: [.fixture], count: 7))
    }
    .environment(NowPlaying.ViewModel())
}
#endif
