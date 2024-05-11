//
//  SeriesGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPBase

struct SeriesGrid: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    let series: [Series]
    
    private var minimumWidth: CGFloat {
        horizontalSizeClass == .compact ? 160.0 : 200.0
    }
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: minimumWidth, maximum: 400), spacing: 15)], spacing: 20) {
            ForEach(series) { item in
                NavigationLink(destination: SeriesView(series: item)) {
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
                    if series.images.isEmpty {
                        ItemImage(image: nil)
                    } else if series.images.count < 4 {
                        ItemImage(image: series.images.randomElement()!)
                    } else {
                        VStack(spacing: 10) {
                            HStack(spacing: 10) {
                                ItemImage(image: series.images[0])
                                ItemImage(image: series.images[1])
                            }
                            HStack(spacing: 10) {
                                ItemImage(image: series.images[2])
                                ItemImage(image: series.images[3])
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
