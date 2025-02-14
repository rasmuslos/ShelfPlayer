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
    let onAppear: ((_ audiobook: Series) -> Void)
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 110.0 : 200.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 12)], spacing: 16) {
            ForEach(series) { item in
                NavigationLink(destination: SeriesView(item)) {
                    SeriesGridItem(series: item)
                }
                .buttonStyle(.plain)
                .onAppear {
                    onAppear(item)
                }
            }
        }
    }
}

extension SeriesGrid {
    struct SeriesGridItem: View {
        let name: String?
        let audiobookIDs: [ItemIdentifier]
        
        init(series: Series) {
            self.name = series.name
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
                .hoverEffect(.highlight)
                
                if let name {
                    Text(name)
                        .modifier(SerifModifier())
                        .lineLimit(1)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            SeriesGrid(series: .init(repeating: .fixture, count: 7)) { _ in }
                .padding(20)
        }
    }
}
#endif
