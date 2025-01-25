//
//  SeriesGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPFoundation

internal struct SeriesGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let series: [Series]
    var onAppear: ((_ audiobook: Series) -> Void)? = nil
    
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
                .onAppear {
                    onAppear?(item)
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
        
        private var flipped: Bool {
            audiobookIDs.count == 3
        }
        
        var body: some View {
            VStack(spacing: 4) {
                Group {
                    if audiobookIDs.isEmpty {
                        ItemImage(item: nil)
                    } else if audiobookIDs.count == 1 {
                        ItemImage(itemID: audiobookIDs.first)
                    } else if audiobookIDs.count < 4 {
                        GeometryReader { proxy in
                            let width = proxy.size.width / 1.6
                            
                            ZStack(alignment: flipped ? .bottomLeading : .topLeading) {
                                Rectangle()
                                    .fill(.clear)
                                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                                
                                Group {
                                    ItemImage(itemID: audiobookIDs[0])
                                    ItemImage(itemID: audiobookIDs[1])
                                        .offset(x: proxy.size.width - width, y: (proxy.size.height - width) * (flipped ? -1 : 1))
                                }
                                .frame(width: width)
                            }
                        }
                        .aspectRatio(1, contentMode: .fill)
                    } else {
                        VStack(spacing: 8) {
                            HStack(spacing: 8) {
                                ItemImage(itemID: audiobookIDs[0])
                                ItemImage(itemID: audiobookIDs[1])
                            }
                            HStack(spacing: 8) {
                                ItemImage(itemID: audiobookIDs[2])
                                ItemImage(itemID: audiobookIDs[3])
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
            SeriesGrid(series: .init(repeating: .fixture, count: 7))
                .padding(20)
        }
    }
}
#endif
