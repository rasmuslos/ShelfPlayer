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
            let startPoint = additionalHeight / height
            
            ZStack(alignment: .bottom) {
                content
                    .safeAreaPadding(.bottom, height)
                
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
            .toolbarBackgroundVisibility(satellite.isNowPlayingVisible ? .hidden : .automatic, for: .tabBar)
            .ignoresSafeArea(edges: .bottom)
        }
    }
}
