//
//  CompactLegacyCollapsedForeground.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 16.09.25.
//

import SwiftUI
import ShelfPlayback

struct CompactLegacyCollapsedForeground: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    let decorative: Bool
    
    var horizontalPadding: CGFloat {
        if #available(iOS 26, *) {
            8
        } else {
            12
        }
    }
    
    @ViewBuilder
    private var label: some View {
        HStack(spacing: 8) {
            GeometryReader { imageGeometryProxy in
                // idk why
                let x = imageGeometryProxy.frame(in: .global).minX
                let y = imageGeometryProxy.frame(in: .global).minY
                
                let size = imageGeometryProxy.size.width
                
                if !decorative {
                    Rectangle()
                        .fill(.clear)
                        .onChange(of: x, initial: true) { viewModel.pillImageX = x }
                        .onChange(of: y, initial: true) { viewModel.pillImageY = y }
                        .onChange(of: size, initial: true) { viewModel.pillImageSize = size }
                }
                
                ItemImage(itemID: satellite.nowPlayingItemID, size: .small, cornerRadius: viewModel.PILL_IMAGE_CORNER_RADIUS)
                    .opacity(!viewModel.isExpanded && viewModel.expansionAnimationCount <= 0 ? 1 : 0)
                    .id((satellite.nowPlayingItemID?.description ?? "huzgfuzgw") + "_nowPlaying_image_compact_legacy")
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
            .id((satellite.nowPlayingItem?.sortName ?? "wwf2foijwvkjw") + "_nowPlaying_text_legacy_compact")
            
            Spacer()
            
            PlaybackBackwardButton()
                .imageScale(.large)
            
            PlaybackSmallTogglePlayButton()
                .imageScale(.large)
                .padding(.horizontal, 8)
        }
        .contentShape(.rect)
        .padding(.horizontal, 20 - horizontalPadding)
        .padding(.vertical, 8)
        .modify {
            if decorative {
                $0
            } else {
                $0
                    .background(.bar, in: .rect(cornerRadius: viewModel.PILL_CORNER_RADIUS))
            }
        }
        .padding(.horizontal, horizontalPadding)
    }
    
    var body: some View {
        if decorative {
            label
        } else {
            GeometryReader { geometryProxy in
                let x = geometryProxy.frame(in: .global).minX
                let y = geometryProxy.frame(in: .global).minY
                
                let width = geometryProxy.frame(in: .global).width
                let height = geometryProxy.frame(in: .global).height
                
                
                Button {
                    viewModel.toggleExpanded()
                } label: {
                    label
                }
                .buttonStyle(.plain)
                .universalContentShape(RoundedRectangle(cornerRadius: viewModel.PILL_CORNER_RADIUS, style: .continuous))
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
                .task {
                    viewModel.isUsingLegacyPillDesign = true
                }
            }
            .frame(height: 56)
        }
    }
}

struct ApplyLegacyCollapsedForeground: ViewModifier {
    @Environment(\.playbackBottomSafeArea) private var playbackBottomSafeArea
    @Environment(\.playbackBottomOffset) private var playbackBottomOffset
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Environment(Satellite.self) private var satellite
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if satellite.nowPlayingItemID != nil && horizontalSizeClass == .compact {
                    CompactLegacyCollapsedForeground(decorative: false)
                        .shadow(color: .black.opacity(0.2), radius: 12)
                        .offset(y: -(playbackBottomOffset + playbackBottomSafeArea))
                }
            }
    }
}
