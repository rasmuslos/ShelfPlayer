//
//  SeriesView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import SwiftUI
import ShelfPlayback

extension SeriesView {
    struct Header: View {
        @Environment(SeriesViewModel.self) private var viewModel
        
        private var amountVisible: Int {
            min(viewModel.audiobookIDs.count, 5)
        }
        
        var body: some View {
            if !viewModel.audiobookIDs.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        ForEach(0..<amountVisible, id: \.description) {
                            let index = amountVisible - $0 - 1
                            let itemID = viewModel.audiobookIDs.isEmpty ? nil : viewModel.audiobookIDs[index]
                            
                            ItemImage(itemID: itemID, size: .regular)
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
                    
                    Group {
                        if let first = viewModel.lazyLoader.items.first {
                            PlayButton(item: first, color: nil)
                        } else if viewModel.lazyLoader.working {
                            PlayButton(item: Episode.placeholder, color: nil)
                                .disabled(true)
                        }
                    }
                    .padding(.horizontal, 20)
                }
                .frame(maxWidth: .infinity)
                .padding(.bottom, 0)
            }
        }
    }
}
