//
//  NowPlayingSheet.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import SPFoundation
import SPPlayback

internal extension NowPlaying {
    struct CompactModifier: ViewModifier {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.colorScheme) private var colorScheme
        
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        var bottomOffset: CGFloat = 88
        
        func body(content: Content) -> some View {
            if horizontalSizeClass == .compact {
                ZStack(alignment: .bottom) {
                    content
                        .allowsHitTesting(!viewModel.expanded)
                    
                    if let item = viewModel.item {
                        ZStack {
                            // Background
                            ZStack {
                                // Prevent content from shining through
                                if viewModel.expanded {
                                    Rectangle()
                                        .foregroundStyle(.background)
                                        .transition(.opacity)
                                        .transaction {
                                            if !viewModel.expanded {
                                                $0.animation = .smooth.delay(0.6)
                                            }
                                        }
                                }
                                
                                // Now playing bar background
                                Rectangle()
                                    .foregroundStyle(.regularMaterial)
                                    .opacity(viewModel.expanded ? 0 : 1)
                                
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
                                .opacity(viewModel.expanded ? 1 : 0)
                            }
                            .allowsHitTesting(false)
                            .mask {
                                VStack(spacing: 0) {
                                    UnevenRoundedRectangle(topLeadingRadius: viewModel.backgroundCornerRadius, topTrailingRadius: viewModel.backgroundCornerRadius, style: .continuous)
                                        .frame(maxHeight: 60)
                                    
                                    // The padding prevents the mask from cutting lines in the background
                                    // during the transformation. They are caused by the `spring` animation.
                                    Rectangle()
                                        .padding(.vertical, -2)
                                    
                                    UnevenRoundedRectangle(bottomLeadingRadius: viewModel.backgroundCornerRadius, bottomTrailingRadius: viewModel.backgroundCornerRadius, style: .continuous)
                                        .frame(maxHeight: 60)
                                }
                                .drawingGroup()
                            }
                            .shadow(color: .black.opacity(0.2), radius: 8)
                            
                            // Drag gesture catcher
                            if viewModel.expanded {
                                Rectangle()
                                    .foregroundStyle(.clear)
                                    .contentShape(.rect)
                                    .modifier(GestureModifier(active: true))
                            }
                            
                            // Foreground
                            VStack(spacing: 0) {
                                CollapsedForeground(item: item)
                                    .opacity(viewModel.expanded ? 0 : 1)
                                    .allowsHitTesting(!viewModel.expanded)
                                
                                ExpandedForeground(item: item)
                            }
                        }
                        .offset(x: 0, y: viewModel.dragOffset)
                        .ignoresSafeArea(.keyboard)
                        .ignoresSafeArea(edges: .all)
                        .toolbarBackground(.hidden, for: .tabBar)
                        .frame(height: viewModel.expanded ? nil : 56)
                        .padding(.horizontal, viewModel.expanded ? 0 : 12)
                        .padding(.bottom, viewModel.expanded ? 0 : bottomOffset)
                        .animation(.snappy(duration: 0.8), value: viewModel.expanded)
                        .modifier(FeedbackModifier())
                    }
                    
                }
                .ignoresSafeArea(edges: .all)
                .modifier(Navigation.NotificationModifier() { _, _, _, _, _, _, _ in
                    viewModel.expanded = false
                })
            } else {
                content
            }
        }
    }
}

private struct ExpandedForeground: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let item: PlayableItem
    
    var body: some View {
        @Bindable var viewModel = viewModel
        
        VStack(spacing: 0) {
            if viewModel.expanded {
                Spacer(minLength: 12)
                
                ItemImage(cover: item.cover, aspectRatio: .none)
                    .shadow(color: .black.opacity(0.4), radius: 20)
                    .scaleEffect(AudioPlayer.shared.playing ? 1 : 0.8)
                    .animation(.spring(duration: 0.3, bounce: 0.6), value: viewModel.playing)
                    .matchedGeometryEffect(id: "image", in: viewModel.namespace, properties: .frame, anchor: .topLeading)
                    .modifier(NowPlaying.GestureModifier(active: true))
                
                Spacer(minLength: 12)
                
                VStack(spacing: 0) {
                    NowPlaying.Title(item: item)
                        .modifier(NowPlaying.GestureModifier(active: true))
                    
                    NowPlaying.Controls(compact: false)
                        .padding(.top, 16)
                    
                    NowPlaying.CompactButtons()
                        .padding(.top, 28)
                        .padding(.bottom, 28)
                }
                .transition(.move(edge: .bottom))
            }
        }
        .overlay(alignment: .top) {
            if viewModel.expanded {
                Button {
                    viewModel.expanded = false
                } label: {
                    Rectangle()
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 4)
                        .clipShape(.rect(cornerRadius: .infinity))
                }
                .buttonStyle(.plain)
                .padding(40)
                .modifier(NowPlaying.GestureModifier(active: true))
                .padding(-40)
                .transition(.asymmetric(insertion: .opacity.animation(.smooth.delay(0.4)), removal: .identity))
            }
        }
        .padding(.horizontal, 28)
        .sensoryFeedback(.success, trigger: viewModel.notifyBookmark)
        .sheet(isPresented: $viewModel.sheetPresented) {
            NowPlaying.Sheet()
        }
    }
}
private struct CollapsedForeground: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    let item: PlayableItem
    
    var body: some View {
        Button {
            viewModel.expanded.toggle()
        } label: {
            HStack(spacing: 8) {
                if !viewModel.expanded {
                    ItemImage(cover: item.cover, cornerRadius: 8)
                        .frame(width: 40, height: 40)
                        .matchedGeometryEffect(id: "image", in: viewModel.namespace, properties: .frame, anchor: .topLeading)
                } else {
                    Rectangle()
                        .hidden()
                        .frame(width: 40, height: 40)
                }
                
                Text(viewModel.chapter?.title ?? item.name)
                    .lineLimit(1)
                
                Spacer()
                
                Group {
                    Group {
                        if viewModel.buffering {
                            ProgressIndicator()
                        } else {
                            Button {
                                AudioPlayer.shared.playing.toggle()
                            } label: {
                                Label("playback.toggle", systemImage: viewModel.playing ?  "pause.fill" : "play.fill")
                                    .labelStyle(.iconOnly)
                                    .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                    .animation(.spring(duration: 0.2, bounce: 0.7), value: viewModel.playing)
                            }
                        }
                    }
                    .transition(.blurReplace)
                    
                    Button {
                        AudioPlayer.shared.skipForwards()
                    } label: {
                        Label("forwards", systemImage: "goforward.\(viewModel.skipForwardsInterval)")
                            .labelStyle(.iconOnly)
                            .symbolEffect(.bounce.up, value: viewModel.notifyForwards)
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
        .modifier(NowPlaying.ContextMenuModifier())
        .padding(.horizontal, 8)
    }
}
