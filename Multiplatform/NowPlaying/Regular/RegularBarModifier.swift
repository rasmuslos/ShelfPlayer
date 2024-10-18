//
//  RegularNowPlayingBarModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit
import SPPlayback

internal extension NowPlaying {
    struct RegularBarModifier: ViewModifier {
        @Default(.skipBackwardsInterval) private var skipBackwardsInterval
        @Default(.skipForwardsInterval) private var skipForwardsInterval
        
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        @State private var width: CGFloat = .zero
        @State private var adjust: CGFloat = .zero
        
        func body(content: Content) -> some View {
            @Bindable var viewModel = viewModel
            
            content
                .safeAreaInset(edge: .bottom) {
                    if let item = viewModel.item {
                        HStack(spacing: 12) {
                            ItemImage(cover: item.cover)
                                .frame(width: 48, height: 48)
                            
                            Group {
                                if let chapterTitle = AudioPlayer.shared.chapter?.title {
                                    Text(chapterTitle)
                                } else {
                                    Text(item.name)
                                }
                            }
                            .lineLimit(1)
                            
                            Spacer()
                            
                            PlaybackSpeedButton()
                                .font(.footnote)
                                .fontWeight(.heavy)
                                .foregroundStyle(.secondary)
                                .modifier(ButtonHoverEffectModifier())
                            
                            Button {
                                AudioPlayer.shared.skipBackwards()
                            } label: {
                                Label("backwards", systemImage: "gobackward.\(skipBackwardsInterval)")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce, value: viewModel.notifyBackwards)
                            }
                            .font(.title3)
                            .modifier(ButtonHoverEffectModifier())
                            
                            Group {
                                if viewModel.buffering {
                                    ProgressView()
                                } else {
                                    Button {
                                        AudioPlayer.shared.playing.toggle()
                                    } label: {
                                        Label("playback.toggle", systemImage: viewModel.playing ? "pause.fill" : "play.fill")
                                            .labelStyle(.iconOnly)
                                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                    }
                                }
                            }
                            .frame(width: 32)
                            .font(.title)
                            .modifier(ButtonHoverEffectModifier())
                            .transition(.blurReplace)
                            
                            Button {
                                AudioPlayer.shared.skipForwards()
                            } label: {
                                Label("forwards", systemImage: "goforward.\(skipBackwardsInterval)")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce, value: viewModel.notifyBackwards)
                            }
                            .font(.title3)
                            .modifier(ButtonHoverEffectModifier())
                        }
                        .padding(.horizontal, 10)
                        .frame(height: 66)
                        .frame(maxWidth: width)
                        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .foregroundStyle(.primary)
                        .background {
                            Rectangle()
                                .foregroundStyle(.bar)
                        }
                        .modifier(NowPlaying.ContextMenuModifier())
                        .clipShape(.rect(cornerRadius: 16, style: .continuous))
                        .shadow(color: .black.opacity(0.25), radius: 20)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 10)
                        .padding(.leading, adjust)
                        .animation(width == .zero ? .none : .spring, value: width)
                        .animation(.spring, value: adjust)
                        .onTapGesture {
                            viewModel.expanded = true
                        }
                        .fullScreenCover(isPresented: $viewModel.expanded) {
                            RegularView()
                                .ignoresSafeArea(edges: .all)
                        }
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NowPlaying.widthChangeNotification)) { notification in
                    if let width = notification.object as? CGFloat {
                        self.width = min(width, 1100)
                    }
                }
                .onReceive(NotificationCenter.default.publisher(for: NowPlaying.offsetChangeNotification)) { notification in
                    if let offset = notification.object as? CGFloat {
                        adjust = offset
                    }
                }
                .environment(viewModel)
        }
    }
}
