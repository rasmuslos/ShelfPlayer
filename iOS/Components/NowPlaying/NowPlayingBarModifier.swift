//
//  NowPlayingBarModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import AudiobooksKit

struct NowPlayingBarModifier: ViewModifier {
    @State var playing = AudioPlayer.shared.isPlaying()
    @State var item = AudioPlayer.shared.item
    
    @State var nowPlayingSheetPresented = false
    @State var skipForwardsInterval = UserDefaults.standard.integer(forKey: "skipForwardsInterval")
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                if let item = item {
                    ZStack {
                        RoundedRectangle(cornerRadius: 15)
                            .toolbarBackground(.hidden, for: .tabBar)
                            .background {
                                Rectangle()
                                    .frame(width: UIScreen.main.bounds.width + 100, height: 300)
                                    .offset(y: 130)
                                    .blur(radius: 25)
                                    .foregroundStyle(.thinMaterial)
                            }
                            .foregroundStyle(.ultraThinMaterial)
                            .overlay {
                                HStack {
                                    ItemImage(image: item.image)
                                        .frame(width: 40, height: 40)
                                        .padding(.leading, 5)
                                    
                                    Text(item.name)
                                        .lineLimit(1)
                                    
                                    Spacer()
                                    
                                    Group {
                                        Button {
                                            AudioPlayer.shared.setPlaying(!playing)
                                        } label: {
                                            Image(systemName: playing ?  "pause.fill" : "play.fill")
                                                .contentTransition(.symbolEffect(.replace))
                                        }
                                        
                                        Button {
                                            AudioPlayer.shared.seek(to: AudioPlayer.shared.getCurrentTime() + Double(skipForwardsInterval))
                                        } label: {
                                            Image(systemName: "goforward.\(skipForwardsInterval)")
                                        }
                                        .padding(.horizontal, 10)
                                    }
                                    .imageScale(.large)
                                }
                                .padding(.horizontal, 6)
                            }
                            .foregroundStyle(.primary)
                            .padding(.horizontal, 15)
                            .padding(.bottom, 10)
                            .frame(height: 65)
                            .shadow(color: .black.opacity(0.25), radius: 20)
                            .onTapGesture {
                                nowPlayingSheetPresented.toggle()
                            }
                            .fullScreenCover(isPresented: $nowPlayingSheetPresented) {
                                NowPlayingSheet(item: item, playing: $playing)
                            }
                    }
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
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.startStopNotification), perform: { _ in
                withAnimation {
                    item = AudioPlayer.shared.item
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.playPauseNotification), perform: { _ in
                withAnimation {
                    playing = AudioPlayer.shared.isPlaying()
                }
            })
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification), perform: { _ in
                withAnimation {
                    skipForwardsInterval = UserDefaults.standard.integer(forKey: "skipForwardsInterval")
                }
            })
    }
}

struct NowPlayingBarSafeAreaModifier: ViewModifier {
    @State var isVisible = AudioPlayer.shared.item != nil
    
    func body(content: Content) -> some View {
        content
            .safeAreaPadding(.bottom, isVisible ? 75 : 0)
            .onReceive(NotificationCenter.default.publisher(for: AudioPlayer.startStopNotification), perform: { _ in
                withAnimation {
                    isVisible = AudioPlayer.shared.item != nil
                }
            })
    }
}

#Preview {
    Text(":)")
        .modifier(NowPlayingBarModifier(item: Audiobook.fixture))
}
