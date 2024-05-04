//
//  RegularNowPlayingBarModifier.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import SPBase
import SPPlayback

extension NowPlaying {
    struct RegularBarModifier: ViewModifier {
        @Default(.skipBackwardsInterval) private var skipBackwardsInterval
        @Default(.skipForwardsInterval) private var skipForwardsInterval
        
        var offset: CGFloat? = nil
        
        @State private var bounce = false
        @State private var animateBackwards = false
        @State private var animateForwards = false
        
        @State private var width: CGFloat = .zero
        @State private var adjust: CGFloat = .zero
        @State private var sheetPresented = false
        
        func body(content: Content) -> some View {
            content
                .safeAreaInset(edge: .bottom) {
                    if let item = AudioPlayer.shared.item {
                        HStack {
                            ItemImage(image: item.image, aspectRatio: .none)
                                .frame(height: 50)
                                .scaleEffect(bounce ? AudioPlayer.shared.playing ? 1.1 : 0.9 : 1)
                                .animation(.spring(duration: 0.2, bounce: 0.7), value: bounce)
                                .onChange(of: AudioPlayer.shared.playing) {
                                    withAnimation {
                                        bounce = true
                                    } completion: {
                                        bounce = false
                                    }
                                }
                            
                            VStack(alignment: .leading) {
                                Group {
                                    if let chapterTitle = AudioPlayer.shared.chapter?.title {
                                        Text(chapterTitle)
                                    } else {
                                        Text(item.name)
                                    }
                                }
                                .lineLimit(1)
                                
                                Group {
                                    if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                                        Text(releaseDate, style: .date)
                                    } else {
                                        Text(AudioPlayer.shared.adjustedTimeLeft.hoursMinutesSecondsString(includeSeconds: false, includeLabels: true))
                                        + Text(verbatim: " ")
                                        + Text("time.left")
                                    }
                                }
                                .lineLimit(1)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            Button {
                                animateBackwards.toggle()
                                AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() - Double(skipBackwardsInterval))
                            } label: {
                                Label("backwards", systemImage: "gobackward.\(skipBackwardsInterval)")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce, value: animateForwards)
                            }
                            .font(.title3)
                            .modifier(ButtonHoverEffectModifier())
                            .padding(.horizontal, 7)
                            
                            Group {
                                if AudioPlayer.shared.buffering {
                                    ProgressIndicator()
                                } else {
                                    Button {
                                        AudioPlayer.shared.playing = !AudioPlayer.shared.playing
                                    } label: {
                                        Label("playback.toggle", systemImage: AudioPlayer.shared.playing ?  "pause.fill" : "play.fill")
                                            .labelStyle(.iconOnly)
                                            .contentTransition(.symbolEffect(.replace.byLayer.downUp))
                                    }
                                }
                            }
                            .transition(.blurReplace)
                            .font(.largeTitle)
                            .modifier(ButtonHoverEffectModifier())
                            .frame(width: 30)
                            
                            Button {
                                animateForwards.toggle()
                                AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() + Double(skipForwardsInterval))
                            } label: {
                                Label("forwards", systemImage: "goforward.\(skipForwardsInterval)")
                                    .labelStyle(.iconOnly)
                                    .symbolEffect(.bounce, value: animateForwards)
                            }
                            .font(.title3)
                            .modifier(ButtonHoverEffectModifier())
                            .padding(.horizontal, 7)
                        }
                        .padding(.horizontal, 8)
                        .frame(height: 66)
                        .frame(maxWidth: width)
                        .foregroundStyle(.primary)
                        .contentShape(.hoverMenuInteraction, RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .modifier(NowPlaying.ContextMenuModifier(item: item, animateForwards: $animateForwards))
                        .background {
                            Rectangle()
                                .foregroundStyle(.regularMaterial)
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                        .hoverEffect(.highlight)
                        .shadow(color: .black.opacity(0.25), radius: 20)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 25)
                        .padding(.leading, adjust)
                        .animation(.spring, value: width)
                        .animation(.spring, value: adjust)
                        .onTapGesture {
                            sheetPresented.toggle()
                        }
                        .fullScreenCover(isPresented: $sheetPresented) {
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
        }
    }
}
