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
    @Default(.skipBackwardsInterval) var skipBackwardsInterval
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
                                    
                                    VStack(alignment: .leading) {
                                        Text(item.name)
                                            .lineLimit(1)
                                        
                                        Group {
                                            if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                                                Text(releaseDate, style: .date)
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
                                    AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() - Double(skipBackwardsInterval))
                                } label: {
                                    Label("backwards", systemImage: "gobackward.\(skipForwardsInterval)")
                                }
                                
                                Button {
                                    animateForwards.toggle()
                                    AudioPlayer.shared.seek(to: AudioPlayer.shared.getItemCurrentTime() + Double(skipForwardsInterval))
                                } label: {
                                    Label("forwards", systemImage: "goforward.\(skipForwardsInterval)")
                                }
                                
                                Divider()
                                
                                Menu {
                                    ChapterSelectMenu()
                                } label: {
                                    Label("chapters", systemImage: "list.dash")
                                }
                                
                                Divider()
                                
                                SleepTimerButton()
                                PlaybackSpeedButton()
                                
                                Divider()
                                
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
                                        if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                                            Text(releaseDate, style: .date)
                                        } else if let audiobook = item as? Audiobook, let seriesName = audiobook.seriesName {
                                            Text(seriesName)
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
