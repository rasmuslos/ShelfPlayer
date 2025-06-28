//
//  EpisodeTable.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

struct EpisodeGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let episodes: [Episode]
    var amount = 2
    
    @State private var width: CGFloat = .zero
    
    private let gap: CGFloat = 12
    private let padding: CGFloat = 20
    
    private var size: CGFloat {
        let minimumSize: CGFloat = 300
        
        let usable = width - padding * 2
        let paddedSize = minimumSize + gap
        
        let amount = CGFloat(Int(usable / paddedSize))
        let available = usable - gap * (amount - 1)
        
        return max(minimumSize, available / amount)
    }
    private var amountVisible: Int {
        min(episodes.count, amount)
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
                LazyHGrid(rows: .init(repeating: GridItem(.flexible(), spacing: 8), count: amountVisible), spacing: 0) {
                    EpisodeList(episodes: episodes, context: .grid, selected: .constant(nil))
                        .padding(.leading, gap)
                        .frame(width: size)
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
        EpisodeGrid(episodes: .init(repeating: .fixture, count: 7))
    }
    .previewEnvironment()
}
#endif
