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
    @Default(.skipForwardsInterval) var skipForwardsInterval
    
    @State private var bounce = false
    @State private var animateForwards = false
    
    @State private var nowPlayingSheetPresented = false
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let item = AudioPlayer.shared.item {
                    ZStack(alignment: .bottom) {
                        Rectangle()
                            .frame(width: UIScreen.main.bounds.width + 100, height: 300)
                            .offset(y: 225)
                            .blur(radius: 25)
                            .foregroundStyle(.thinMaterial)
                        
                        RoundedRectangle(cornerRadius: 15)
                            .toolbarBackground(.hidden, for: .tabBar)
                            .foregroundStyle(.ultraThinMaterial)
                            .overlay {
                                HStack {
                                    ItemImage(image: item.image)
                                        .frame(width: 40, height: 40)
                                        .padding(.leading, 5)
                                        .scaleEffect(bounce ? AudioPlayer.shared.playing ? 1.1 : 0.9 : 1)
                                        .animation(.spring(duration: 0.2, bounce: 0.7), value: bounce)
                                        .onChange(of: AudioPlayer.shared.playing) {
                                            withAnimation {
                                                bounce = true
                                            } completion: {
                                                bounce = false
                                            }
                                        }
                                    
                                    Text(item.name)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Group {
                                        Button {
                                            AudioPlayer.shared.playing = !AudioPlayer.shared.playing
                                        } label: {
                                            Image(systemName: AudioPlayer.shared.playing ?  "pause.fill" : "play.fill")
                                                .contentTransition(.symbolEffect(.replace))
                                        }
                                        
                                        Button {
                                            animateForwards.toggle()
                                            AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() + Double(skipForwardsInterval))
                                        } label: {
                                            Image(systemName: "goforward.\(skipForwardsInterval)")
                                                .bold()
                                                .symbolEffect(.bounce, value: animateForwards)
                                        }
                                        .padding(.horizontal, 10)
                                    }
                                    .imageScale(.large)
                                }
                                .padding(.horizontal, 6)
                            }
                            .foregroundStyle(.primary)
                            .frame(width: UIScreen.main.bounds.width - 30, height: 60)
                            .shadow(color: .black.opacity(0.25), radius: 20)
                            .contextMenu {
                                Button {
                                    AudioPlayer.shared.stopPlayback()
                                } label: {
                                    Label("playback.stop", systemImage: "xmark")
                                }
                            } preview: {
                                VStack(alignment: .leading) {
                                    ItemImage(image: item.image)
                                        .padding(.bottom, 10)
                                    
                                    Group {
                                        if let episode = item as? Episode, let releaseDate = episode.formattedReleaseDate {
                                            Text(releaseDate)
                                        } else if let audiobook = item as? Audiobook, let series = audiobook.series.audiobookSeriesName ?? audiobook.series.name {
                                            Text(series)
                                        }
                                    }
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                    
                                    Text(item.name)
                                        .font(.headline)
                                    
                                    if let author = item.author {
                                        Text(author)
                                            .font(.subheadline)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .frame(width: 250)
                                .padding()
                            }
                            .padding(.bottom, 10)
                            .onTapGesture {
                                nowPlayingSheetPresented.toggle()
                            }
                            .fullScreenCover(isPresented: $nowPlayingSheetPresented) {
                                NowPlayingSheet()
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
