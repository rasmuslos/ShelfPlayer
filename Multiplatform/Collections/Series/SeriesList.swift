//
//  SeriesList.swift
//  iOS
//
//  Created by Rasmus Krämer on 03.02.24.
//

import SwiftUI
import SPFoundation

struct SeriesList: View {
    let series: [Series]
    
    var body: some View {
        ForEach(series) { item in
            NavigationLink(destination: SeriesView(series: item)) {
                SeriesRow(series: item)
            }
            .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
        }
    }
}

extension SeriesList {
    struct SeriesRow: View {
        let series: Series
        
        var body: some View {
            HStack {
                let count = min(series.covers.count, 5)
                ZStack {
                    ForEach(0..<count, id: \.hashValue) {
                        let index = (count - 1) - $0
                        
                        ItemImage(image: series.covers[$0])
                            .frame(height: 50)
                            .offset(x: CGFloat(index) * 20)
                            .scaleEffect(index == 0 ? 1 : index == 1 ? 0.95 : index == 2 ? 0.9 : index == 3 ? 0.85 : index == 4 ? 0.8 : 0)
                            .shadow(radius: 2)
                    }
                }
                .frame(height: 70)
                
                VStack(alignment: .leading) {
                    Text(series.name)
                        .modifier(SerifModifier())
                    Text("series.count \(series.covers.count)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.leading, CGFloat(count - 1) * 20)
            }
        }
    }
}

#Preview {
    NavigationStack {
        List {
            SeriesList(series: .init(repeating: [.fixture], count: 7))
        }
        .listStyle(.plain)
    }
}
