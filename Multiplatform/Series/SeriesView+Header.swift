//
//  SeriesView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal extension SeriesView {
    struct Header: View {
        @Environment(SeriesViewModel.self) private var viewModel
        
        var body: some View {
            if !viewModel.images.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        ForEach(0..<viewModel.headerImageCount, id: \.hashValue) {
                            let index = viewModel.headerImageCount - $0 - 1
                            
                            ItemImage(cover: viewModel.images[index])
                                .frame(width: index == 0 ? 200 : index == 1 || index == 2 ? 180 : 160)
                                .offset(x: index == 0 ? 0 : index == 1 ? -40 : index == 2 ? 40 : index == 3 ? -75 : 75)
                        }
                    }
                    
                    Text(viewModel.series.name)
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
        }
    }
}
