//
//  CompactPlaybackModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI
import ShelfPlayback

struct CompactPlaybackModifier: ViewModifier {
    @Environment(\.playbackBottomOffset) private var playbackBottomOffset
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    let ready: Bool
    
    private var nowPlayingCornerRadius: CGFloat {
        guard viewModel.isExpanded else {
            return viewModel.pillHeight
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
        if ready && horizontalSizeClass == .compact {
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
                            ItemImage(itemID: satellite.nowPlayingItemID, size: .regular, cornerRadius: viewModel.isExpanded ? viewModel.EXPANDED_IMAGE_CORNER_RADIUS : viewModel.PILL_IMAGE_CORNER_RADIUS)
                                .frame(width: viewModel.isExpanded ? viewModel.expandedImageSize : viewModel.pillImageSize)
                                .offset(x: viewModel.isExpanded ? viewModel.expandedImageX : viewModel.pillImageX,
                                        y: viewModel.isExpanded ? viewModel.expandedImageY : viewModel.pillImageY)
                                .opacity(viewModel.expansionAnimationCount > 0 ? 1 : 0)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                    }
                    .ignoresSafeArea()
            }
        } else {
            content
        }
    }
}

struct CompactLegacyCollapsedForeground: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        GeometryReader { geometryProxy in
            let x = geometryProxy.frame(in: .global).minX
            let y = geometryProxy.frame(in: .global).minY
            
            let width = geometryProxy.frame(in: .global).width
            let height = geometryProxy.frame(in: .global).height
            
            Button {
                
            } label: {
                HStack(spacing: 8) {
                    GeometryReader { imageGeometryProxy in
                        // idk why
                        let x = imageGeometryProxy.frame(in: .global).minX
                        let y = imageGeometryProxy.frame(in: .global).minY
                        
                        let size = imageGeometryProxy.size.width
                        
                        Rectangle()
                            .fill(.clear)
                            .onChange(of: x, initial: true) { viewModel.pillImageX = x }
                            .onChange(of: y, initial: true) { viewModel.pillImageY = y }
                            .onChange(of: size, initial: true) { viewModel.pillImageSize = size }
                        
                        if !viewModel.isExpanded && viewModel.expansionAnimationCount <= 0 {
                            ItemImage(itemID: satellite.nowPlayingItemID, size: .small, cornerRadius: viewModel.PILL_IMAGE_CORNER_RADIUS)
                                .id(satellite.nowPlayingItemID)
                        }
                    }
                    .frame(width: 40, height: 40)
                    
                    Group {
                        if let currentItem = satellite.nowPlayingItem {
                            Text(currentItem.name)
                                .lineLimit(1)
                        } else {
                            Text("loading")
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    Spacer()
                    
                    PlaybackBackwardButton()
                        .imageScale(.large)
                    
                    PlaybackSmallTogglePlayButton()
                        .imageScale(.large)
                        .padding(.horizontal, 8)
                }
                .contentShape(.rect)
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(.bar, in: .rect(cornerRadius: 16))
            }
            .buttonStyle(.plain)
            .universalContentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .contextMenu {
                PlaybackMenuActions()
            } preview: {
                if let currentItem = satellite.nowPlayingItem {
                    PlayableItemContextMenuPreview(item: currentItem)
                }
            }
            .onChange(of: x, initial: true) { viewModel.pillX = x }
            .onChange(of: y, initial: true) { viewModel.pillY = y }
            .onChange(of: width, initial: true) { viewModel.pillWidth = width }
            .onChange(of: height, initial: true) { viewModel.pillHeight = height }
        }
        .frame(height: 56)
        .padding(.horizontal, 12)
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
        }
    }
    .modifier(CompactPlaybackModifier(ready: true))
    .previewEnvironment()
}

#Preview {
    ScrollView {
        CompactLegacyCollapsedForeground()
            .previewEnvironment()
    }
    .background(.blue)
}
#endif
