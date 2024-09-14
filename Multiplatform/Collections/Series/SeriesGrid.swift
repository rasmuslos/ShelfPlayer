//
//  SeriesGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPFoundation

struct SeriesGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let series: [Series]
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 160.0 : 200.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 16)], spacing: 20) {
            ForEach(series) { item in
                NavigationLink(destination: SeriesView(item)) {
                    SeriesGridItem(series: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

private struct SeriesGridItem: View {
    let series: Series
    
    private var flipped: Bool {
        series.covers.count == 3
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Group {
                if series.covers.isEmpty {
                    ItemImage(cover: nil)
                } else if series.covers.count == 1 {
                    ItemImage(cover: series.covers.first)
                } else if series.covers.count < 4 {
                    GeometryReader { proxy in
                        let width = proxy.size.width / 1.6
                        
                        ZStack(alignment: flipped ? .bottomLeading : .topLeading) {
                            Rectangle()
                                .fill(.clear)
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                            
                            Group {
                                ItemImage(cover: series.covers[0])
                                ItemImage(cover: series.covers[1])
                                    .offset(x: proxy.size.width - width, y: (proxy.size.height - width) * (flipped ? -1 : 1))
                            }
                            .frame(width: width)
                        }
                    }
                    .aspectRatio(1, contentMode: .fill)
                } else {
                    VStack(spacing: 8) {
                        HStack(spacing: 8) {
                            ItemImage(cover: series.covers[0])
                            ItemImage(cover: series.covers[1])
                        }
                        HStack(spacing: 8) {
                            ItemImage(cover: series.covers[2])
                            ItemImage(cover: series.covers[3])
                        }
                    }
                }
            }
            .hoverEffect(.highlight)
            
            Text(series.name)
                .modifier(SerifModifier())
                .lineLimit(1)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            SeriesGrid(series: .init(repeating: [.fixture], count: 7))
                .padding(20)
        }
    }
}
#endif
