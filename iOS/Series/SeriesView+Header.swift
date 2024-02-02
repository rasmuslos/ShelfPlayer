//
//  SeriesView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import SPBase

extension SeriesView {
    struct Header: View {
        let series: Series
        
        var body: some View {
            if !series.images.isEmpty {
                VStack {
                    HStack {
                        Spacer()
                        
                        let count = min(series.images.count, 5)
                        ZStack {
                            ForEach(0..<count, id: \.hashValue) {
                                let index = count - $0 - 1
                                
                                ItemImage(image: series.images[index])
                                    .frame(width: index == 0 ? 200 : index == 1 || index == 2 ? 175 : 140)
                                    .offset(x: index == 0 ? 0 : index == 1 ? -50 : index == 2 ? 50 : index == 3 ? -90 : 90)
                                    .shadow(radius: 5)
                            }
                        }
                        
                        Spacer()
                    }
                    
                    Text(series.name)
                        .fontDesign(.serif)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(verbatim: "")
                            }
                        }
                }
                .listRowSeparator(.hidden)
                .padding(.bottom)
            }
        }
    }
}
