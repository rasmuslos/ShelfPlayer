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
            min(viewModel.lazyLoader.loadedCount, 5)
        }
        
        private func offset(for index: Int) -> CGFloat {
            switch index {
                case 0: 0
                case 1: 40
                case 2: -40
                case 3: 75
                case 4: -75
                default: 0
            }
        }
        private func scale(for index: Int) -> CGFloat {
            switch index {
                case 0: 1
                case 1, 2: 0.9
                case 3, 4: 0.8
                default: 0
            }
        }
        private func zIndex(for index: Int) -> Double {
            switch index {
                case 0: 5
                case 1, 2: 4
                case 3, 4: 3
                default: 0
            }
        }
        
        var body: some View {
            if !viewModel.lazyLoader.items.isEmpty {
                VStack(spacing: 16) {
                    ZStack {
                        ForEach(0..<amountVisible, id: \.hashValue) { index in
                            ItemImage(item: viewModel.lazyLoader.items[index], size: .regular)
                                .zIndex(zIndex(for: index))
                                .padding(.horizontal, 70)
                                .scaleEffect(scale(for: index))
                                .offset(x: offset(for: index))
                        }
                    }
                    .accessibilityElement(children: .ignore)
                    .accessibilityAddTraits(.isImage)
                    .frame(maxWidth: 360)
                    .padding(.top, 12)
                    
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
                    
                    
                    if let highlighted = viewModel.highlighted {
                        PlayButton(item: highlighted)
                            .padding(.horizontal, 20)
                            .disabled(highlighted == .placeholder)
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
    }
}
