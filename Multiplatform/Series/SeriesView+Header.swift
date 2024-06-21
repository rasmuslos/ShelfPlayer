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
        let audiobooks: [Audiobook]
        
        @State private var images = [Item.Image]()
        
        private var count: Int {
            min(images.count, 5)
        }
        
        var body: some View {
            if !images.isEmpty {
                VStack {
                    ZStack {
                        ForEach(0..<count, id: \.hashValue) {
                            let index = count - $0 - 1
                            
                            ItemImage(image: images[index])
                                .frame(width: index == 0 ? 200 : index == 1 || index == 2 ? 180 : 160)
                                .offset(x: index == 0 ? 0 : index == 1 ? -40 : index == 2 ? 40 : index == 3 ? -80 : 80)
                                .shadow(radius: 4)
                        }
                    }
                    
                    Text(series.name)
                        .font(.title)
                        .modifier(SerifModifier())
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .toolbar {
                            ToolbarItem(placement: .principal) {
                                Text(verbatim: "")
                            }
                        }
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 20)
            }
            
            EmptyView()
                .onChange(of: audiobooks, initial: true) {
                    if !series.images.isEmpty {
                        images = series.images
                    } else {
                        images = audiobooks.compactMap { $0.image }
                    }
                }
        }
    }
}
