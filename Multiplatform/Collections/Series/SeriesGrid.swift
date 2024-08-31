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
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 15)], spacing: 20) {
            ForEach(series) { item in
                NavigationLink(destination: SeriesView(item)) {
                    SeriesGridItem(series: item)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

extension SeriesGrid {
    struct SeriesGridItem: View {
        let series: Series
        
        var body: some View {
            VStack {
                Group {
                    if series.covers.isEmpty {
                        ItemImage(image: nil)
                    } else if series.covers.count < 4 {
                        // TODO: more
                        ItemImage(image: series.covers.randomElement()!)
                    } else {
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                ItemImage(image: series.covers[0])
                                ItemImage(image: series.covers[1])
                            }
                            HStack(spacing: 10) {
                                ItemImage(image: series.covers[2])
                                ItemImage(image: series.covers[3])
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
}

#if DEBUG
#Preview {
    NavigationStack {
        ScrollView {
            SeriesGrid(series: [
                Series.fixture,
                Series.fixture,
                Series.fixture,
                Series.fixture,
                Series.fixture,
                Series.fixture,
            ])
            .padding(20)
        }
    }
}
#endif
