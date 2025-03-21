//
//  CompactPlaybackModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.02.25.
//

import SwiftUI
import ShelfPlayerKit
import SPPlayback

struct CompactPlaybackModifier: ViewModifier {
    @Environment(\.playbackBottomOffset) private var playbackBottomOffset
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(Satellite.self) private var satellite
    @Environment(PlaybackViewModel.self) private var viewModel
    
    let ready: Bool
    
    private var pushAmount: CGFloat {
        viewModel.pushAmount
    }
    
    static let height: CGFloat = 56
    
    func body(content: Content) -> some View {
        if ready && horizontalSizeClass == .compact {
            GeometryReader { geometryProxy in
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(.black)
                    
                    content
                        .allowsHitTesting(!viewModel.isExpanded)
                        .overlay {
                            Color.white.opacity(min(0.1, (1 - viewModel.pushAmount)))
                                .animation(.smooth(duration: 0.4), value: viewModel.isExpanded)
                        }
                        .visualEffect { [pushAmount] content, _ in
                            content
                                .scaleEffect(pushAmount, anchor: .top)
                        }
                        .mask(alignment: .center) {
                            let totalWidth = geometryProxy.size.width + geometryProxy.safeAreaInsets.leading + geometryProxy.safeAreaInsets.trailing
                            let width = totalWidth * viewModel.pushAmount
                            let leadingOffset = (totalWidth - width) / 2
                            
                            RoundedRectangle(cornerRadius: satellite.isNowPlayingVisible && !satellite.isSheetPresented ? viewModel.pushContainerCornerRadius(leadingOffset: leadingOffset) : 0, style: .continuous)
                                .fill(.background)
                                .frame(width: width,
                                       height: (geometryProxy.size.height + geometryProxy.safeAreaInsets.top + geometryProxy.safeAreaInsets.bottom) * viewModel.pushAmount)
                        }
                        .animation(.smooth, value: viewModel.pushAmount)
                            
                    if satellite.isNowPlayingVisible {
                        ZStack {
                            // Background
                            ZStack {
                                // Prevent content from shining through
                                if viewModel.isExpanded {
                                    Rectangle()
                                        .foregroundStyle(.background)
                                        .transition(.opacity)
                                        .transaction {
                                            if !viewModel.isExpanded {
                                                $0.animation = .smooth.delay(0.6)
                                            }
                                        }
                                }
                                
                                // Now playing bar background
                                Rectangle()
                                    .foregroundStyle(.regularMaterial)
                                    .opacity(viewModel.isExpanded ? 0 : 1)
                                
                                // Now playing view background
                                Group {
                                    if colorScheme == .dark {
                                        Rectangle()
                                            .foregroundStyle(.background.secondary)
                                    } else {
                                        Rectangle()
                                        #if DEBUG && false
                                            .foregroundStyle(.background.opacity(0.8))
                                        #else
                                            .foregroundStyle(.background)
                                        #endif
                                    }
                                }
                                .opacity(viewModel.isExpanded ? 1 : 0)
                                .animation(.smooth(duration: 0.1), value: viewModel.isExpanded)
                            }
                            .allowsHitTesting(false)
                            .mask {
                                VStack(spacing: 0) {
                                    UnevenRoundedRectangle(topLeadingRadius: viewModel.backgroundCornerRadius,
                                                           topTrailingRadius: viewModel.backgroundCornerRadius,
                                                           style: .continuous)
                                    .frame(maxHeight: 60)
                                    
                                    // The padding prevents the mask from cutting lines in the background
                                    // during the transformation. They are caused by the `spring` animation.
                                    Rectangle()
                                        .padding(.vertical, -2)
                                    
                                    UnevenRoundedRectangle(bottomLeadingRadius: viewModel.backgroundCornerRadius,
                                                           bottomTrailingRadius: viewModel.backgroundCornerRadius,
                                                           style: .continuous)
                                    .frame(maxHeight: 60)
                                }
                                .drawingGroup()
                            }
                            .shadow(color: .black.opacity(0.2), radius: 8)
                            
                            // Drag gesture catcher
                            if viewModel.isExpanded {
                                Rectangle()
                                    .foregroundStyle(.clear)
                                    .contentShape(.rect)
                                    .modifier(PlaybackDragGestureCatcher(active: true))
                            }
                            
                            // Foreground
                            VStack(spacing: 0) {
                                CollapsedForeground()
                                    .opacity(viewModel.isExpanded ? 0 : 1)
                                    .contentShape(.rect)
                                    .highPriorityGesture(DragGesture()
                                        .onChanged {
                                            if $0.translation.height < -100 || $0.velocity.height < -2000 {
                                                viewModel.isExpanded = true
                                            }
                                        }
                                    )
                                    .contextMenu {
                                        PlaybackMenuActions()
                                    } preview: {
                                        if let currentItem = satellite.currentItem {
                                            PlayableItemContextMenuPreview(item: currentItem)
                                        }
                                    }
                                    .allowsHitTesting(!viewModel.isExpanded)
                                
                                ExpandedForeground(height: geometryProxy.size.height)
                                    .allowsHitTesting(viewModel.isExpanded)
                            }
                        }
                        .frame(height: viewModel.isExpanded ? nil : Self.height)
                        .padding(.horizontal, viewModel.isExpanded ? 0 : 12)
                        .padding(.bottom, viewModel.isExpanded ? 0 : playbackBottomOffset)
                        .offset(x: 0, y: viewModel.dragOffset)
                        .toolbarBackground(.hidden, for: .tabBar)
                        .animation(.snappy(duration: 0.6), value: viewModel.isExpanded)
                    }
                    
                }
                .frame(width: geometryProxy.size.width + geometryProxy.safeAreaInsets.leading + geometryProxy.safeAreaInsets.trailing,
                       height: geometryProxy.size.height + geometryProxy.safeAreaInsets.top + geometryProxy.safeAreaInsets.bottom)
                /*
                 .modifier(Navigation.NotificationModifier() { _, _, _, _, _, _, _, _ in
                 viewModel.expanded = false
                 })
                 */
            }
            .ignoresSafeArea()
        } else {
            content
        }
    }
}

private struct ExpandedForeground: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(\.namespace) private var namespace
    
    let height: CGFloat
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(spacing: 0) {
            if viewModel.isExpanded {
                Spacer(minLength: 12)
                
                if !viewModel.isQueueVisible {
                    ItemImage(itemID: satellite.currentItemID, size: .large, aspectRatio: .none, contrastConfiguration: nil)
                        .id(satellite.currentItemID)
                        .padding(.horizontal, -8)
                        .shadow(color: .black.opacity(0.4), radius: 20)
                        .matchedGeometryEffect(id: "image", in: namespace!, properties: .frame, anchor: viewModel.isExpanded ? .topLeading : .topTrailing)
                        .scaleEffect(satellite.isPlaying ? 1 : 0.8)
                        .animation(.spring(duration: 0.3, bounce: 0.6), value: satellite.isPlaying)
                        .modifier(PlaybackDragGestureCatcher(active: true))
                    
                    Spacer(minLength: 12)
                    
                    PlaybackTitle()
                        .matchedGeometryEffect(id: "text", in: namespace!, properties: .frame, anchor: .center)
                    
                    Spacer(minLength: 12)
                    
                    PlaybackControls()
                        .compositingGroup()
                        .transition(.move(edge: .bottom).combined(with: .opacity).animation(.snappy(duration: 0.1)))
                    
                    Spacer(minLength: 12)
                } else {
                    HStack(spacing: 12) {
                        Button {
                            withAnimation(.snappy) {
                                viewModel.isQueueVisible.toggle()
                            }
                        } label: {
                            ItemImage(itemID: satellite.currentItemID, size: .regular, aspectRatio: .none, contrastConfiguration: nil)
                        }
                        .buttonStyle(.plain)
                        .frame(height: 72)
                        .shadow(color: .black.opacity(0.4), radius: 20)
                        .matchedGeometryEffect(id: "image", in: namespace!, properties: .frame, anchor: viewModel.isExpanded ? .topLeading : .topTrailing)
                        .modifier(PlaybackDragGestureCatcher(active: true))
                        
                        PlaybackTitle()
                            .modifier(PlaybackDragGestureCatcher(active: true))
                            .matchedGeometryEffect(id: "text", in: namespace!, properties: .frame, anchor: .center)
                    }
                    
                    PlaybackQueue()
                        .padding(.vertical, 12)
                        .frame(maxHeight: height - 230)
                        .transition(.move(edge: .bottom).combined(with: .opacity).animation(.snappy(duration: 0.1)))
                }
                
                PlaybackActions()
                    .compositingGroup()
                    .transition(.move(edge: .bottom).combined(with: .opacity).animation(.snappy(duration: 0.1)))
                
                Spacer(minLength: 12)
            }
        }
        .overlay(alignment: .top) {
            if viewModel.isExpanded {
                Button {
                    viewModel.isExpanded = false
                } label: {
                    Rectangle()
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 4)
                        .clipShape(.rect(cornerRadius: .infinity))
                }
                .buttonStyle(.plain)
                .padding(40)
                .contentShape(.rect)
                .modifier(PlaybackDragGestureCatcher(active: true))
                .padding(-40)
                .transition(.asymmetric(insertion: .opacity.animation(.smooth.delay(0.3)), removal: .identity))
            }
        }
        .padding(.horizontal, 28)
    }
}
private struct CollapsedForeground: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(\.namespace) private var namespace
    
    var body: some View {
        Button {
            viewModel.isExpanded.toggle()
        } label: {
            HStack(spacing: 8) {
                if !viewModel.isExpanded {
                    ItemImage(itemID: satellite.currentItemID, size: .small, cornerRadius: 8)
                        .frame(width: 40, height: 40)
                        .matchedGeometryEffect(id: "image", in: namespace!, properties: .frame, anchor: .topLeading)
                } else {
                    Rectangle()
                        .hidden()
                        .frame(width: 40, height: 40)
                }
                
                // Text(viewModel.chapter?.title ?? item.name)
                if let currentItem = satellite.currentItem {
                    Text(currentItem.name)
                        .lineLimit(1)
                } else {
                    Text("loading")
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                Button("backwards", systemImage: "gobackward.\(viewModel.skipBackwardsInterval)") {
                    satellite.skip(forwards: false)
                }
                .labelStyle(.iconOnly)
                .imageScale(.large)
                .symbolEffect(.bounce.up, value: viewModel.notifySkipBackwards)
                
                ZStack {
                    Group {
                        Image(systemName: "play.fill")
                        Image(systemName: "pause.fill")
                    }
                    .hidden()
                    
                    Group {
                        if let currentItemID = satellite.currentItemID, satellite.isLoading(observing: currentItemID) {
                            ProgressIndicator()
                        } else if satellite.isBuffering || satellite.currentItemID == nil {
                            ProgressIndicator()
                        } else {
                            Button {
                                satellite.togglePlaying()
                            } label: {
                                Label("playback.toggle", systemImage: satellite.isPlaying ? "pause.fill" : "play.fill")
                                    .labelStyle(.iconOnly)
                                    .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                    .animation(.spring(duration: 0.2, bounce: 0.7), value: satellite.isPlaying)
                            }
                        }
                    }
                    .transition(.blurReplace)
                }
                .imageScale(.large)
                .padding(.horizontal, 8)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.primary)
        .frame(height: 56)
        .clipShape(.rect(cornerRadius: 12, style: .continuous))
        .contentShape(.hoverMenuInteraction, .rect(cornerRadius: 16, style: .continuous))
        // .modifier(NowPlaying.ContextMenuModifier())
        .padding(.horizontal, 8)
    }
}

#if DEBUG
#Preview {
    TabView {
        Tab(String(":)"), systemImage: "command") {
            NavigationStack {
                ZStack {
                    Rectangle()
                        .fill(.blue.opacity(0.6))
                        .ignoresSafeArea()
                    
                    Rectangle()
                        .fill(.yellow)
                    
                    Image(systemName: "command")
                }
            }
            .modifier(TabContentPlaybackModifier())
        }
    }
    .modifier(CompactPlaybackModifier(ready: true))
    .environment(\.playbackBottomOffset, 88)
    .previewEnvironment()
}
#endif
