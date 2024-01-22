//
//  SeriesRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import SPBase

struct SeriesRow: View {
    let series: Series
    
    var body: some View {
        HStack {
            let count = min(series.images.count, 5)
            ZStack {
                ForEach(0..<count, id: \.hashValue) {
                    let index = (count - 1) - $0
                    
                    ItemImage(image: series.images[$0])
                        .frame(height: 50)
                        .offset(x: CGFloat(index) * 20)
                        .scaleEffect(index == 0 ? 1 : index == 1 ? 0.95 : index == 2 ? 0.9 : index == 3 ? 0.85 : index == 4 ? 0.8 : 0)
                        .shadow(radius: 2)
                }
            }
            .frame(height: 70)
            
            VStack(alignment: .leading) {
                Text(series.name)
                    .fontDesign(.serif)
                Text("series.count \(series.images.count)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.leading, CGFloat(count - 1) * 20)
        }
    }
}

#Preview {
    List {
        SeriesRow(series: Series.fixture)
        SeriesRow(series: Series.fixture)
        SeriesRow(series: Series.fixture)
        SeriesRow(series: Series.fixture)
        SeriesRow(series: Series.fixture)
        SeriesRow(series: Series.fixture)
    }
    .listStyle(.plain)
}
