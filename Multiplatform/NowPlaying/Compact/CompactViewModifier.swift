//
//  NowPlayingSheet.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import SPBase
import SPPlayback

extension NowPlaying {
    struct CompactViewModifier: ViewModifier {
        @Namespace private var namespace
        @Environment(\.colorScheme) private var colorScheme
        @Environment(\.presentationMode) private var presentationMode
        
        var offset: CGFloat? = nil
        
        @State private var viewState = CompactViewState.init()
        
        @State private var showChaptersSheet = false
        
        @State private var controlsDragging = false
        @State private var dragOffset: CGFloat = .zero
        
        private var presentedItem: PlayableItem? {
            if viewState.presented, let item = AudioPlayer.shared.item {
                return item
            }
            
            return nil
        }
        
        func body(content: Content) -> some View {
            ZStack {
                content
                    .allowsHitTesting(!viewState.presented)
                    .onAppear {
                        viewState.namespace = namespace
                    }
                    .modifier(Navigation.NavigationModifier() {
                        viewState.setNowPlayingViewPresented(false)
                    })
                
                Group {
                    if presentedItem != nil {
                        Rectangle()
                            .ignoresSafeArea(edges: .all)
                            .foregroundStyle(colorScheme == .dark ? .black : .white)
                            .zIndex(1)
                            .transition(.asymmetric(
                                insertion: .modifier(active: BackgroundInsertTransitionModifier(active: true, offset: offset), identity: BackgroundInsertTransitionModifier(active: false, offset: offset)),
                                removal: .modifier(active: BackgroundRemoveTransitionModifier(active: true, offset: offset), identity: BackgroundRemoveTransitionModifier(active: false, offset: offset)))
                            )
                            .onAppear {
                                dragOffset = 0
                            }
                    }
                    
                    if viewState.containerPresented {
                        VStack {
                            if let item = presentedItem {
                                Spacer()
                                
                                ItemImage(image: item.image, aspectRatio: .none)
                                    .shadow(radius: 15)
                                    .padding(.vertical, 10)
                                    .scaleEffect(AudioPlayer.shared.playing ? 1 : 0.8)
                                    .animation(.spring(duration: 0.3, bounce: 0.6), value: AudioPlayer.shared.playing)
                                    .matchedGeometryEffect(id: "image", in: namespace, properties: .frame, anchor: .topLeading, isSource: viewState.presented)
                                
                                Spacer()
                                
                                Title(item: item, namespace: namespace)
                                
                                Group {
                                    Controls(namespace: namespace, compact: false, controlsDragging: $controlsDragging)
                                    Buttons()
                                        .padding(.top, 20)
                                        .padding(.bottom, 30)
                                }
                                .transition(.opacity.animation(.linear(duration: 0.2)))
                            }
                        }
                        .zIndex(2)
                        .overlay(alignment: .top) {
                            if presentedItem != nil {
                                Button {
                                    viewState.setNowPlayingViewPresented(false)
                                } label: {
                                    Rectangle()
                                        .foregroundStyle(.gray.opacity(0.75))
                                        .frame(width: 50, height: 7)
                                        .clipShape(RoundedRectangle(cornerRadius: 10000))
                                }
                                .transition(.asymmetric(
                                    insertion: .opacity.animation(.linear(duration: 0.1).delay(0.3)),
                                    removal: .opacity.animation(.linear(duration: 0.05))))
                            }
                        }
                        .padding(.horizontal, 30)
                        .padding(.top, UIApplication.shared.connectedScenes.flatMap { ($0 as? UIWindowScene)?.windows ?? [] }.first { $0.isKeyWindow }?.safeAreaInsets.top)
                        .simultaneousGesture(
                            DragGesture(minimumDistance: 25, coordinateSpace: .global)
                                .onChanged {
                                    if controlsDragging {
                                        return
                                    }
                                    
                                    if $0.velocity.height > 3000 {
                                        viewState.setNowPlayingViewPresented(false) {
                                            dragOffset = 0
                                        }
                                    } else if $0.velocity.height < -3000 {
                                        dragOffset = 0
                                    } else {
                                        dragOffset = max(0, $0.translation.height)
                                    }
                                }
                                .onEnded {
                                    if $0.translation.height > 200 && dragOffset != 0 {
                                        viewState.setNowPlayingViewPresented(false) {
                                            dragOffset = 0
                                        }
                                    } else {
                                        dragOffset = 0
                                    }
                                }
                        )
                    }
                }
                .allowsHitTesting(presentedItem != nil)
                .offset(y: dragOffset)
                .animation(.spring, value: dragOffset)
            }
            .ignoresSafeArea(edges: .all)
            .environment(viewState)
        }
    }
}

// TODO: can this be shared between AmpFin & ShelfPlayer?

extension NowPlaying {
    @Observable
    final class CompactViewState {
        var namespace: Namespace.ID?
        
        private(set) var presented = false
        private(set) var containerPresented = false
        
        private(set) var active = false
        private(set) var lastActive = Date()
        
        var safeNamespace: Namespace.ID {
            namespace ?? Namespace().wrappedValue
        }
        
        func setNowPlayingViewPresented(_ presented: Bool, completion: (() -> Void)? = nil) {
            if active && lastActive.timeIntervalSince(Date()) > -1 {
                return
            }
            
            active = true
            lastActive = Date()
            
            if presented {
                containerPresented = true
            }
            
            withAnimation(.spring(duration: 0.6, bounce: 0.1)) {
                self.presented = presented
            } completion: {
                self.active = false
                
                if !self.presented {
                    self.containerPresented = false
                }
                
                completion?()
            }
        }
    }
}

private extension NowPlaying {
    struct BackgroundInsertTransitionModifier: ViewModifier {
        @Environment(CompactViewState.self) private var viewState
        
        let active: Bool
        var offset: CGFloat?
        
        func body(content: Content) -> some View {
            content
                .mask(alignment: .bottom) {
                    Rectangle()
                        .frame(maxHeight: active ? 0 : .infinity)
                        .padding(.horizontal, active ? 12 : 0)
                }
                .offset(y: active ? (offset ?? 92) * -1 - 56 : 0)
        }
    }
    
    // This is more a "collapse" than a move thing
    struct BackgroundRemoveTransitionModifier: ViewModifier {
        @Environment(CompactViewState.self) private var viewState
        
        let active: Bool
        var offset: CGFloat?
        
        func body(content: Content) -> some View {
            content
                .mask(alignment: .bottom) {
                    Rectangle()
                        .frame(maxHeight: active ? 0 : .infinity)
                        .padding(.horizontal, active ? 12 : 0)
                        .animation(Animation.smooth(duration: 0.5, extraBounce: 0.1), value: active)
                }
                .offset(y: active ? (offset ?? 92) * -1 : 0)
        }
    }
}
