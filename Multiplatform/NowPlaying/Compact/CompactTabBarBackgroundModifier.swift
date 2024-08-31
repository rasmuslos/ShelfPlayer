//
//  NowPlayingBarModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import SPFoundation

internal extension NowPlaying {
    struct CompactTabBarBackgroundModifier: ViewModifier {
        @Environment(ViewModel.self) private var viewModel
        
        func body(content: Content) -> some View {
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
                                        .frame(height: 250)
                                }
                            }
                            .foregroundStyle(.bar)
                            .padding(.bottom, -225)
                            .allowsHitTesting(false)
                            .toolbarBackground(.hidden, for: .tabBar)
                            .ignoresSafeArea(.keyboard)
                            .ignoresSafeArea(edges: .all)
                    }
                }
        }
    }
}
