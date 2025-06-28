//
//  RegularPlaybackModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.06.25.
//

import SwiftUI
import ShelfPlayback

struct RegularPlaybackModifier: ViewModifier {
    @Environment(\.playbackBottomOffset) private var playbackBottomOffset
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    static let height: CGFloat = 56
    
    private var pushAmount: CGFloat {
        viewModel.pushAmount
    }
    
    @ViewBuilder
    private func label(_ itemID: ItemIdentifier) -> some View {
        HStack(spacing: 8) {
            ItemImage(itemID: itemID, size: .small)
            
            VStack(alignment: .leading, spacing: 2) {
                if let currentItem = satellite.nowPlayingItem {
                    Text(currentItem.name)
                        .lineLimit(1)
                        .font(.headline)
                    
                    Text(currentItem.authors, format: .list(type: .and))
                        .lineLimit(1)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                } else {
                    Text("loading")
                        .foregroundStyle(.secondary)
                }
            }
            
            Spacer(minLength: 12)
            
            PlaybackRateButton()
                .font(.caption2.smallCaps())
                .foregroundStyle(.secondary)
                .padding(.trailing, 12)
            
            PlaybackBackwardButton()
                .font(.title3)
            
            ZStack {
                Group {
                    Image(systemName: "play")
                    Image(systemName: "pause")
                }
                .hidden()
                
                PlaybackTogglePlayButton()
            }
            .font(.title2)
            .padding(.horizontal, 8)
            
            PlaybackForwardButton()
                .font(.title3)
            
            PlaybackSleepTimerButton()
                .padding(.horizontal, 12)
                .labelStyle(.iconOnly)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .contentShape(.rect)
    }
    
    @ViewBuilder
    private func leftHandContent() -> some View {
        VStack(spacing: 0) {
            Spacer(minLength: 20)
            
            ItemImage(itemID: satellite.nowPlayingItemID, size: .large, aspectRatio: .none, contrastConfiguration: nil)
                .id(satellite.nowPlayingItemID)
                .shadow(color: .black.opacity(0.4), radius: 20)
                .scaleEffect(satellite.isPlaying ? 1 : 0.8)
                .animation(.spring(duration: 0.3, bounce: 0.6), value: satellite.isPlaying)
                .modifier(PlaybackDragGestureCatcher(active: true))
            
            Spacer(minLength: 20)
            
            PlaybackTitle()
            
            Spacer(minLength: 20)
            
            PlaybackControls()
            
            Spacer(minLength: 20)
        }
    }
    
    func body(content: Content) -> some View {
        if horizontalSizeClass == .regular {
            content
                .fullScreenCover(isPresented: .init { viewModel.isExpanded } set: { viewModel.isExpanded = $0 }) {
                    ZStack {
                        Rectangle()
                            .fill(.background)
                            .contentShape(.rect)
                            .modifier(PlaybackDragGestureCatcher(active: true))
                        
                        HStack(spacing: 40) {
                            leftHandContent()
                                .frame(maxWidth: 400)
                            
                            PlaybackQueue()
                        }
                        .padding(.horizontal, 40)
                    }
                }
                .safeAreaInset(edge: .bottom) {
                    if let currentItemID = satellite.nowPlayingItemID {
                        GeometryReader { geometryProxy in
                            ZStack {
                                RoundedRectangle(cornerRadius: 12, style: .continuous)
                                    .fill(.bar)
                                
                                Button {
                                    viewModel.isExpanded = true
                                } label: {
                                    label(currentItemID)
                                }
                                .buttonStyle(.plain)
                            }
                            .universalContentShape(.rect(cornerRadius: 16, style: .continuous))
                            .contextMenu {
                                PlaybackMenuActions()
                            } preview: {
                                if let currentItem = satellite.nowPlayingItem {
                                    PlayableItemContextMenuPreview(item: currentItem)
                                }
                            }
                            .padding(.horizontal, 20)
                            .animation(.smooth, value: geometryProxy.size.width)
                        }
                        .frame(height: Self.height)
                    }
                }
        } else {
            content
        }
    }
}

#if DEBUG
#Preview {
    TabView {
        Tab(role: .search) {
            ScrollView {
                ForEach(1..<1000) {
                    Text(verbatim: $0.formatted(.number))
                    
                    Rectangle()
                        .fill(.blue)
                }
            }
            .modifier(RegularPlaybackModifier())
        }
    }
    .tabViewStyle(.sidebarAdaptable)
    .previewEnvironment()
}
#endif
