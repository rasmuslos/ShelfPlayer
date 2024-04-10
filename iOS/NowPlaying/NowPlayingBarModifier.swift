//
//  NowPlayingBarModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import Defaults
import SPBase
import SPPlayback

struct NowPlayingBarModifier: ViewModifier {
    @Default(.skipForwardsInterval) private var skipForwardsInterval
    @Environment(NowPlayingViewState.self) private var nowPlayingViewState
    
    @State private var bounce = false
    @State private var animateForwards = false
    
    @State private var nowPlayingSheetPresented = false
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let item = AudioPlayer.shared.item {
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .frame(height: 300)
                            .mask {
                                VStack(spacing: 0) {
                                    LinearGradient(colors: [.black.opacity(0), .black], startPoint: .top, endPoint: .bottom)
                                        .frame(height: 50)
                                    
                                    Rectangle()
                                        .frame(height: 250)
                                }
                            }
                            .foregroundStyle(.regularMaterial)
                            .padding(.bottom, -225)
                            .allowsHitTesting(false)
                            .toolbarBackground(.hidden, for: .tabBar)
                        
                        if !nowPlayingViewState.presented {
                            HStack {
                                ItemImage(image: item.image)
                                    .frame(width: 40, height: 40)
                                    .scaleEffect(bounce ? AudioPlayer.shared.playing ? 1.1 : 0.9 : 1)
                                    .animation(.spring(duration: 0.2, bounce: 0.7), value: bounce)
                                    .matchedGeometryEffect(id: "image", in: nowPlayingViewState.namespace, properties: .frame, anchor: .top)
                                    .onChange(of: AudioPlayer.shared.playing) {
                                        withAnimation {
                                            bounce = true
                                        } completion: {
                                            bounce = false
                                        }
                                    }
                                
                                VStack(alignment: .leading) {
                                    Text(item.name)
                                        .lineLimit(1)
                                        .matchedGeometryEffect(id: "title", in: nowPlayingViewState.namespace, properties: .frame, anchor: .top)
                                    
                                    Group {
                                        if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                                            Text(releaseDate, style: .date)
                                                .matchedGeometryEffect(id: "releaseDate", in: nowPlayingViewState.namespace, properties: .frame, anchor: .top)
                                        } else {
                                            Text((AudioPlayer.shared.duration - AudioPlayer.shared.currentTime).hoursMinutesSecondsString(includeSeconds: false, includeLabels: true))
                                            + Text(verbatim: " ")
                                            + Text("time.left")
                                        }
                                    }
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                }
                                
                                Spacer()
                                
                                Group {
                                    Group {
                                        if AudioPlayer.shared.buffering {
                                            ProgressView()
                                        } else {
                                            Button {
                                                AudioPlayer.shared.playing = !AudioPlayer.shared.playing
                                            } label: {
                                                Image(systemName: AudioPlayer.shared.playing ?  "pause.fill" : "play.fill")
                                                    .contentTransition(.symbolEffect(.replace))
                                            }
                                        }
                                    }
                                    .transition(.blurReplace)
                                    
                                    Button {
                                        animateForwards.toggle()
                                        AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() + Double(skipForwardsInterval))
                                    } label: {
                                        Image(systemName: "goforward.\(skipForwardsInterval)")
                                            .symbolEffect(.bounce, value: animateForwards)
                                    }
                                    .padding(.horizontal, 10)
                                }
                                .imageScale(.large)
                            }
                            .frame(height: 56)
                            .padding(.horizontal, 8)
                            .foregroundStyle(.primary)
                            .background {
                                Rectangle()
                                    .foregroundStyle(.regularMaterial)
                            }
                            .transition(.move(edge: .bottom))
                            .clipShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
                            .modifier(NowPlayingBarContextMenuModifier(item: item, animateForwards: $animateForwards))
                            .shadow(color: .black.opacity(0.25), radius: 20)
                            .padding(.bottom, 10)
                            .padding(.horizontal, 8)
                            .zIndex(1)
                            .onTapGesture {
                                nowPlayingViewState.setNowPlayingViewPresented(true)
                            }
                        }
                    }
                }
            }
    }
}

struct NowPlayingBarSafeAreaModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.bottom, AudioPlayer.shared.item != nil ? 75 : 0)
    }
}

#Preview {
    TabView {
        Rectangle()
            .ignoresSafeArea()
            .foregroundStyle(.red)
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label(":)", systemImage: "command")
            }
    }
}
