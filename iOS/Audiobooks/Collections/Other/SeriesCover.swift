//
//  SeriesCover.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPBase

struct SeriesCover: View {
    let series: Series
    
    var body: some View {
        VStack {
            if series.images.isEmpty {
                ItemImage(image: nil)
            } else if series.images.count < 4 {
                ItemImage(image: series.images[0])
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

#Preview {
    SeriesCover(series: Series.fixture)
}
