//
//  NowPlayingBarModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import SPFoundation

internal extension NowPlaying {
    struct BackgroundModifier: ViewModifier {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(ViewModel.self) private var viewModel
        
        var bottomOffset: CGFloat = 0
        
        func body(content: Content) -> some View {
            if horizontalSizeClass == .compact {
                content
                    .safeAreaInset(edge: .bottom) {
                        // Tab bar background
                        if viewModel.item != nil {
                            Rectangle()
                                .frame(height: 300)
                                .mask {
                                    VStack(spacing: 0) {
                                        LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                                            .frame(height: 50)
                                        
                                        Rectangle()
                                            .frame(height: 150)
                                    }
                                }
                                .ignoresSafeArea(.keyboard)
                                .ignoresSafeArea(edges: .all)
                                .foregroundStyle(.bar)
                                .padding(.bottom, -175 + bottomOffset)
                                .allowsHitTesting(false)
                                .toolbarBackground(.hidden, for: .tabBar)
                        }
                    }
            } else {
                content
            }
        }
    }
}
