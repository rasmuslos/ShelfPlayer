//
//  SeriesGrid.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import ShelfPlayerKit

struct SeriesGrid: View {
    let series: [Series]
    
    var body: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 20) {
            ForEach(Array(series.enumerated()), id: \.offset) { index, item in
                NavigationLink(destination: SeriesView(series: item)) {
                    SeriesCover(series: item)
                        .padding(.trailing, index % 2 == 0 ? 5 : 0)
                        .padding(.leading, index % 2 == 1 ? 5 : 0)
                }
                .buttonStyle(.plain)
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
