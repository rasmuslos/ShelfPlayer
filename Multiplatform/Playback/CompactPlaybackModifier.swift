//
//  CompactPlaybackModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI
import ShelfPlayback

struct CompactPlaybackModifier: ViewModifier {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    private var nowPlayingCornerRadius: CGFloat {
        guard viewModel.isExpanded else {
            return viewModel.PILL_CORNER_RADIUS
        }
        
        if viewModel.expansionAnimationCount > 0 || viewModel.translationY > 0 || viewModel.translateYAnimationCount > 0 {
            return UIScreen.main.displayCornerRadius
        }
        
        return 0
    }
    
    @ViewBuilder
    private func nowPlayingCapsuleMirror(proxy geometryProxy: GeometryProxy) -> some View {
        let height = geometryProxy.size.height + geometryProxy.safeAreaInsets.top + geometryProxy.safeAreaInsets.bottom
        let width = geometryProxy.size.width + geometryProxy.safeAreaInsets.leading + geometryProxy.safeAreaInsets.trailing
        
        RoundedRectangle(cornerRadius: nowPlayingCornerRadius, style: .continuous)
            .modify {
                if colorScheme == .dark {
                    $0
                        .fill(.background.secondary)
                } else {
                    $0
                        .fill(.background)
                }
            }
            .opacity(viewModel.isNowPlayingBackgroundVisible ? 1 : 0)
            .offset(viewModel.isExpanded ? .zero : .init(width: viewModel.pillX + geometryProxy.safeAreaInsets.leading,
                                                         height: viewModel.pillY - viewModel.translationY))
            .frame(width: viewModel.isExpanded ? width : viewModel.pillWidth,
                   height: viewModel.isExpanded ? height : viewModel.pillHeight)
    }
    
    func body(content: Content) -> some View {
        if horizontalSizeClass != .compact {
            content
        } else {
            GeometryReader { geometryProxy in
                let height = geometryProxy.size.height + geometryProxy.safeAreaInsets.top + geometryProxy.safeAreaInsets.bottom
                let width = geometryProxy.size.width + geometryProxy.safeAreaInsets.leading + geometryProxy.safeAreaInsets.trailing
                
                content
                    .overlay {
                        ZStack(alignment: .topLeading) {
                            nowPlayingCapsuleMirror(proxy: geometryProxy)
                                .modifier(PlaybackDragGestureCatcher(height: height))
                                .allowsHitTesting(viewModel.isNowPlayingBackgroundVisible)
                                .accessibilityHidden(true)
                            
                            PlaybackCompactExpandedForeground(height: height, safeAreTopInset: geometryProxy.safeAreaInsets.top, safeAreBottomInset: geometryProxy.safeAreaInsets.bottom)
                                .frame(width: width, height: height)
                                .mask(alignment: .topLeading) {
                                    nowPlayingCapsuleMirror(proxy: geometryProxy)
                                }
                                .allowsHitTesting(viewModel.isExpanded)
                                .accessibilityHidden(!viewModel.isExpanded)
                        }
                        .offset(y: viewModel.translationY)
                    }
                    .overlay(alignment: .topLeading) {
                        if viewModel.showCompactPlaybackBarOnExpandedViewCount > 0 {
                            Group {
                                if #available(iOS 26, *) {
                                    PlaybackBottomBarPill(decorative: true)
                                        .frame(width: viewModel.pillWidth, height: viewModel.pillHeight)
                                } else {
                                    CompactLegacyCollapsedForeground(decorative: true)
                                }
                            }
                            .transition(.opacity)
                            .offset(x: viewModel.pillX, y: viewModel.isExpanded ? viewModel.translationY : viewModel.pillY)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                        }
                    }
                    .overlay(alignment: .topLeading) {
                        ItemImage(itemID: satellite.nowPlayingItemID, size: .regular, cornerRadius: viewModel.isExpanded ? viewModel.EXPANDED_IMAGE_CORNER_RADIUS : viewModel.PILL_IMAGE_CORNER_RADIUS)
                            .frame(width: viewModel.isExpanded ? viewModel.expandedImageSize : viewModel.pillImageSize)
                            .offset(x: viewModel.isExpanded ? viewModel.expandedImageX : viewModel.pillImageX,
                                    y: viewModel.isExpanded ? viewModel.expandedImageY : viewModel.pillImageY)
                            .opacity(viewModel.expansionAnimationCount > 0 ? 1 : 0)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                            .id((satellite.nowPlayingItemID?.description ?? "woifoiwefoijwef") + "_nowPlaying_image_animation")
                        
                    }
                    .ignoresSafeArea()
                    .environment(\.playbackBottomSafeArea, geometryProxy.safeAreaInsets.bottom)
            }
        }
    }
}

#if DEBUG
#Preview {
    TabView {
        Tab(String(":)"), systemImage: "command") {
            NavigationStack {
                ScrollView {
                    Rectangle()
                        .fill(.blue)
                        .frame(height: 10_000)
                }
                .ignoresSafeArea()
            }
            .modifier(PlaybackTabContentModifier())
        }
        
        Tab(role: .search) {
            
        }
    }
    .modify {
        if #available(iOS 26, *) {
            $0
                .tabBarMinimizeBehavior(.onScrollDown)
                .tabViewBottomAccessory {
                    PlaybackBottomBarPill()
                }
        } else {
            $0
                .modifier(ApplyLegacyCollapsedForeground())
        }
    }
    .modifier(CompactPlaybackModifier())
    .environment(\.playbackBottomOffset, 60)
    .previewEnvironment()
}

#Preview {
    ScrollView {
        CompactLegacyCollapsedForeground(decorative: false)
            .previewEnvironment()
    }
    .background(.blue)
}
#endif
