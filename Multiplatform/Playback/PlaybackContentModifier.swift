//
//  TabValuePlaybackModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI

struct TabContentPlaybackModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    func body(content: Content) -> some View {
        GeometryReader { geometryProxy in
            // 32 is at the middle axis of the pill
            let additionalHeight: CGFloat = 44
            let height = geometryProxy.safeAreaInsets.bottom + additionalHeight
            let startPoint = (additionalHeight / height) / 2
            
            ZStack(alignment: .bottom) {
                content
                    .environment(\.playbackBottomSafeAreaPadding, geometryProxy.safeAreaInsets.bottom)
                
                if satellite.isNowPlayingVisible {
                    Rectangle()
                        .fill(.bar)
                        .frame(height: height)
                        .mask {
                            LinearGradient(stops: [.init(color: .clear, location: 0),
                                                   .init(color: .black, location: startPoint),
                                                   .init(color: .black, location: 1)],
                                           startPoint: .top, endPoint: .bottom)
                        }
                }
            }
            .toolbarBackgroundVisibility(satellite.isNowPlayingVisible ? .hidden : .automatic, for: .tabBar)
            .ignoresSafeArea(edges: satellite.isNowPlayingVisible ? .bottom : [])
        }
    }
}

struct PlaybackSafeAreaPaddingModifier: ViewModifier {
    @Environment(\.playbackBottomSafeAreaPadding) private var playbackBottomSafeAreaPadding
    @Environment(\.playbackBottomOffset) private var playbackBottomOffset
    
    @Environment(Satellite.self) private var satellite
    
    private var totalHeight: CGFloat {
        CompactPlaybackModifier.height + playbackBottomOffset
    }
    private var padding: CGFloat {
        if satellite.isNowPlayingVisible {
            max(0, (totalHeight - playbackBottomSafeAreaPadding))
        } else {
            0
        }
    }
    
    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.bottom, padding)
    }
}
