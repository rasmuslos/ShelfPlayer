//
//  SeriesGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPBase

struct SeriesGrid: View {
    let series: [Series]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            ForEach(Array(series.enumerated()), id: \.offset) { index, item in
                NavigationLink(destination: SeriesView(series: item)) {
                    SeriesGridItem(series: item)
                        .padding(.trailing, index % 2 == 0 ? 5 : 0)
                        .padding(.leading, index % 2 == 1 ? 5 : 0)
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
                if series.images.isEmpty {
                    ItemImage(image: nil)
                } else if series.images.count < 4 {
                    ItemImage(image: series.images.randomElement()!)
                } else {
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                        ItemImage(image: series.images[0])
                        ItemImage(image: series.images[1])
                        ItemImage(image: series.images[2])
                        ItemImage(image: series.images[3])
                    }
                }
                Text(series.name)
                    .fontDesign(.serif)
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
            .padding()
        }
    }
}
