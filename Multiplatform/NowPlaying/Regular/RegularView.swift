//
//  RegularNowPlayingView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import SPFoundation
import SPPlayback

internal extension NowPlaying {
    struct RegularView: View {
        @Environment(ViewModel.self) private var viewModel
        @Environment(\.dismiss) private var dismiss
        
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
                
                if let item = viewModel.item {
                    Rectangle()
                        .fill(.background)
                        .modifier(NowPlaying.GestureModifier(active: true))
                    
                    VStack(spacing: 0) {
                        HStack(spacing: 40) {
                            VStack(spacing: 0) {
                                Spacer()
                                
                                ItemImage(cover: item.cover, aspectRatio: .none)
                                    .shadow(radius: 16)
                                    .padding(.vertical, 10)
                                    .scaleEffect(AudioPlayer.shared.playing ? 1 : 0.8)
                                    .animation(.spring(duration: 0.3, bounce: 0.6), value: AudioPlayer.shared.playing)
                                
                                Spacer()
                                
                                Title(item: item)
                                Controls(compact: true)
                                    .padding(.top, 12)
                                    .padding(.bottom, 32)
                            }
                            .frame(maxWidth: 475)
                            .modifier(NowPlaying.GestureModifier(active: true))
                            
                            Sheet()
                                .padding(.top, 40)
                        }
                        
                        RegularButtons()
                            .modifier(NowPlaying.GestureModifier(active: true))
                    }
                    .padding(.bottom, 20)
                    .padding(.horizontal, 40)
                    .padding(.top, 40)
                    // this has to be here!
                    .ignoresSafeArea(edges: .all)
                    .overlay(alignment: .top) {
                        Button {
                            dismiss()
                        } label: {
                            Rectangle()
                                .foregroundStyle(.white.opacity(0.4))
                                .frame(width: 52, height: 8)
                                .clipShape(.rect(cornerRadius: .infinity))
                        }
                        .modifier(ButtonHoverEffectModifier(hoverEffect: .lift))
                        .padding(.top, 36)
                    }
                    .modifier(Navigation.NotificationModifier() { _, _, _, _, _, _, _ in
                        dismiss()
                    })
                }
            }
        }
    }
}
