//
//  RegularNowPlayingView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import SPFoundation
import SPPlayback

extension NowPlaying {
    struct RegularView: View {
        @Namespace private var namespace
        @Environment(\.dismiss) var dismiss
        
        @State private var bookmarksActive = false
        @State private var controlsDragging = false
        @State private var availableWidth: CGFloat = .zero
        
        var body: some View {
            ZStack {
                GeometryReader { proxy in
                    Color.clear
                        .onChange(of: proxy.size.width, initial: true) {
                            availableWidth = proxy.size.width
                        }
                }
                .frame(height: 0)
                
                if let item = AudioPlayer.shared.item {
                    Rectangle()
                        .foregroundStyle(.background)
                    
                    VStack {
                        HStack(spacing: availableWidth < 1000 ? 20 : 80) {
                            VStack {
                                Spacer()
                                
                                ItemImage(image: item.image, aspectRatio: .none)
                                    .shadow(radius: 15)
                                    .padding(.vertical, 10)
                                    .scaleEffect(AudioPlayer.shared.playing ? 1 : 0.8)
                                    .animation(.spring(duration: 0.3, bounce: 0.6), value: AudioPlayer.shared.playing)
                                
                                Spacer()
                                
                                Title(item: item, namespace: namespace)
                                Controls(namespace: namespace, compact: true, controlsDragging: $controlsDragging)
                                    .padding(.bottom, 30)
                                
                            }
                            .frame(width: min(availableWidth / 2.25, 450))
                            
                            NotableMomentsView(includeHeader: false, bookmarksActive: $bookmarksActive)
                                .frame(maxWidth: .infinity)
                        }
                        
                        Buttons(notableMomentsToggled: $bookmarksActive)
                    }
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 25, coordinateSpace: .global)
                            .onEnded {
                                if $0.translation.height > 200 {
                                    dismiss()
                                }
                            }
                    )
                    .padding(.bottom, 20)
                    .padding(.horizontal, 40)
                    .padding(.top, 60)
                    .ignoresSafeArea(edges: .all)
                    .overlay(alignment: .top) {
                        Button {
                            dismiss()
                        } label: {
                            Rectangle()
                                .foregroundStyle(.gray.opacity(0.75))
                                .frame(width: 50, height: 7)
                                .clipShape(RoundedRectangle(cornerRadius: 10000))
                        }
                        .modifier(ButtonHoverEffectModifier(hoverEffect: .lift))
                        .padding(.top, 35)
                    }
                    .modifier(Navigation.NavigationModifier() {
                        dismiss()
                    })
                }
            }
        }
    }
}
