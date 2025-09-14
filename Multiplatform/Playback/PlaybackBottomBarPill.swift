//
//  PlaybackBottomBarPill.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 14.09.25.
//

import SwiftUI
import ShelfPlayback

@available(iOS 26.0, *)
struct PlaybackBottomBarPill: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    @Environment(\.namespace) private var namespace
    @Environment(\.tabViewBottomAccessoryPlacement) private var accessoryPlacement
    
    var body: some View {
        GeometryReader { geometryProxy in
            let x = geometryProxy.frame(in: .global).minX
            let y = geometryProxy.frame(in: .global).minY
            
            let width = geometryProxy.frame(in: .global).width
            let height = geometryProxy.frame(in: .global).height
            
            Button {
                viewModel.toggleExpanded()
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
                        
                            
                        ItemImage(itemID: satellite.nowPlayingItemID, size: .small, cornerRadius: viewModel.PILL_IMAGE_CORNER_RADIUS)
                            .opacity(!viewModel.isExpanded && viewModel.expansionAnimationCount <= 0 ? 1 : 0)
                    }
                    .aspectRatio(1, contentMode: .fit)
                    .frame(width: height - 16)
                    
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
                .padding(.horizontal, 16)
                .frame(width: width, height: height)
            }
            .buttonStyle(.plain)
            .onChange(of: x, initial: true) { viewModel.pillX = x }
            .onChange(of: y, initial: true) { viewModel.pillY = y }
            .onChange(of: width, initial: true) { viewModel.pillWidth = width }
            .onChange(of: height, initial: true) { viewModel.pillHeight = height }
            .contextMenu {
                PlaybackMenuActions()
            } preview: {
                if let currentItem = satellite.nowPlayingItem {
                    PlayableItemContextMenuPreview(item: currentItem)
                }
            }
            .id((satellite.nowPlayingItem?.sortName ?? "wsrfgd_") + "_nowPlaying")
        }
    }
}

#Preview {
    if #available(iOS 26.0, *) {
        TabView {
            ForEach(["Tab 1", "Tab 2", "Tab 3"].enumerated(), id: \.offset) { (index, tab) in
                Tab(tab, systemImage: "command") {
                    ScrollView {
                        ForEach(0..<100) { _ in
                            Rectangle()
                                .fill(.blue)
                                .frame(height: 400)
                        }
                    }
                    .ignoresSafeArea()
                }
                .badge(index)
            }
            
            Tab(role: .search) {
                
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            PlaybackBottomBarPill()
        }
        .previewEnvironment()
    } else {
        Text(verbatim: ":(")
    }
}
