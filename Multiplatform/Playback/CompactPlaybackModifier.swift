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
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme
    
    @Environment(Satellite.self) private var satellite
    @Environment(PlaybackViewModel.self) private var viewModel
    
    let ready: Bool
    let bottomOffset: CGFloat
    
    @ViewBuilder
    private func rect(geometryProxy: GeometryProxy) -> some View {
        RoundedRectangle(cornerRadius: UIScreen.main.displayCornerRadius, style: .continuous)
            .fill(.background)
            .frame(width: geometryProxy.size.width * (viewModel.isPushing ? (viewModel.pushAmount + 0.01) : 1))
            .padding(.top, viewModel.isPushing ? 0.5 * geometryProxy.size.height * (1 - viewModel.pushAmount) : 0)
            .ignoresSafeArea()
    }
    
    private var isPushing: Bool {
        viewModel.isPushing
    }
    private var pushAmount: CGFloat {
        viewModel.pushAmount
    }
    
    func body(content: Content) -> some View {
        if ready && horizontalSizeClass == .compact {
            GeometryReader { geometryProxy in
                ZStack(alignment: .bottom) {
                    Rectangle()
                        .fill(.black)
                        .ignoresSafeArea(edges: .all)
                    
                    rect(geometryProxy: geometryProxy)
                    
                    content
                        .allowsHitTesting(!viewModel.isExpanded)
                        .padding(.top, 0.17)
                        .visualEffect { [isPushing, pushAmount] content, _ in
                            content
                                .scaleEffect(isPushing ? pushAmount : 1, anchor: .center)
                        }
                        .mask {
                            rect(geometryProxy: geometryProxy)
                        }
                    
                    if let currentItem = satellite.currentItem {
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
                                            .foregroundStyle(.background)
                                    }
                                }
                                .opacity(viewModel.isExpanded ? 1 : 0)
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
                                CollapsedForeground(item: currentItem)
                                    .opacity(viewModel.isExpanded ? 0 : 1)
                                    .highPriorityGesture(DragGesture()
                                        .onChanged {
                                            if $0.translation.height < -100 || $0.velocity.height < -2000 {
                                                viewModel.isExpanded = true
                                            }
                                        }
                                    )
                                    .allowsHitTesting(!viewModel.isExpanded)
                                
                                ExpandedForeground(item: currentItem)
                            }
                        }
                        .offset(x: 0, y: viewModel.dragOffset)
                        .ignoresSafeArea(.all)
                        .ignoresSafeArea(edges: .all)
                        .toolbarBackground(.hidden, for: .tabBar)
                        .frame(height: viewModel.isExpanded ? nil : 56)
                        .padding(.horizontal, viewModel.isExpanded ? 0 : 12)
                        .padding(.bottom, viewModel.isExpanded ? 0 : bottomOffset)
                        .animation(.snappy(duration: 0.6), value: viewModel.isExpanded)
                    }
                    
                }
                .ignoresSafeArea(edges: .all)
                .animation(.smooth, value: viewModel.pushAmount)
                /*
                 .modifier(Navigation.NotificationModifier() { _, _, _, _, _, _, _, _ in
                 viewModel.expanded = false
                 })
                 */
            }
        } else {
            content
        }
    }
}

private struct ExpandedForeground: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(\.namespace) private var namespace
    
    let item: PlayableItem
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(spacing: 0) {
            if viewModel.isExpanded {
                Spacer(minLength: 12)
                
                ItemImage(item: item, size: .large, aspectRatio: .none, contrastConfiguration: nil)
                    .shadow(color: .black.opacity(0.4), radius: 20)
                    .scaleEffect(satellite.isPlaying ? 1 : 0.8)
                    .animation(.spring(duration: 0.3, bounce: 0.6), value: satellite.isPlaying)
                    .matchedGeometryEffect(id: "image", in: namespace!, properties: .frame, anchor: viewModel.isExpanded ? .topLeading : .topTrailing)
                    .modifier(PlaybackDragGestureCatcher(active: true))
                
                Spacer(minLength: 12)
                
                VStack(spacing: 0) {
                    /*
                    NowPlaying.Title(item: item)
                        .modifier(PlaybackDragGestureCatcher(active: true))
                    
                    NowPlaying.Controls(compact: false)
                        .padding(.top, 16)
                    
                    NowPlaying.CompactButtons()
                        .padding(.top, 28)
                        .padding(.bottom, 28)
                     */
                }
                .transition(.move(edge: .bottom))
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
                .modifier(PlaybackDragGestureCatcher(active: true))
                .padding(-40)
                .transition(.asymmetric(insertion: .opacity.animation(.smooth.delay(0.3)), removal: .identity))
            }
        }
        .padding(.horizontal, 28)
        // .sensoryFeedback(.success, trigger: viewModel.notifyBookmark)
        /*
        .sheet(isPresented: $viewModel.sheetPresented) {
            NowPlaying.Sheet()
        }
         */
    }
}
private struct CollapsedForeground: View {
    @Environment(PlaybackViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    @Environment(\.namespace) private var namespace
    
    let item: PlayableItem
    
    var body: some View {
        Button {
            viewModel.isExpanded.toggle()
        } label: {
            HStack(spacing: 8) {
                if !viewModel.isExpanded {
                    ItemImage(item: item, size: .small, cornerRadius: 8)
                        .frame(width: 40, height: 40)
                        .matchedGeometryEffect(id: "image", in: namespace!, properties: .frame, anchor: .topLeading)
                } else {
                    Rectangle()
                        .hidden()
                        .frame(width: 40, height: 40)
                }
                
                // Text(viewModel.chapter?.title ?? item.name)
                Text(item.name)
                    .lineLimit(1)
                
                Spacer()
                
                Group {
                    Group {
                        if satellite.isLoading(observing: item.id) && satellite.isBuffering {
                            ProgressIndicator()
                        } else {
                            Button {
                                satellite.play()
                            } label: {
                                Label("playback.toggle", systemImage: satellite.isPlaying ? "pause.fill" : "play.fill")
                                    .labelStyle(.iconOnly)
                                    .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                    .animation(.spring(duration: 0.2, bounce: 0.7), value: satellite.isPlaying)
                            }
                        }
                    }
                    .transition(.blurReplace)
                    
                    Button {
                        // AudioPlayer.shared.skipForwards()
                    } label: {
                        // Label("forwards", systemImage: "goforward.\(viewModel.skipForwardsInterval)")
                        Label("forwards", systemImage: "goforward.\(30)")
                            .labelStyle(.iconOnly)
                            // .symbolEffect(.bounce.up, value: viewModel.notifyForwards)
                    }
                    .padding(.horizontal, 8)
                }
                .imageScale(.large)
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

#Preview {
    TabView {
    }
    .modifier(CompactPlaybackModifier(ready: true, bottomOffset: 88))
    .previewEnvironment()
}
