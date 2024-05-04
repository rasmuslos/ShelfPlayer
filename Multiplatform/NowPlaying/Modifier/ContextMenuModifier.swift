//
//  NowPlayingBarContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 10.04.24.
//

import SwiftUI
import Defaults
import SPBase
import SPPlayback

extension NowPlaying {
    struct ContextMenuModifier: ViewModifier {
        @Default(.skipBackwardsInterval) private var skipBackwardsInterval
        @Default(.skipForwardsInterval) private var skipForwardsInterval
        
        let item: PlayableItem
        
        @Binding var animateForwards: Bool
        
        func body(content: Content) -> some View {
            content
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
                    
                    if let episode = item as? Episode {
                        Button {
                            Navigation.navigate(episodeId: episode.id, podcastId: episode.podcastId)
                        } label: {
                            Label("episode.view", systemImage: "waveform")
                        }
                        
                        Button(action: {
                            Navigation.navigate(podcastId: episode.podcastId)
                        }) {
                            Label("podcast.view", systemImage: "tray.full")
                            Text(episode.podcastName)
                        }
                    }
                    
                    if let audiobook = item as? Audiobook {
                        Button {
                            Navigation.navigate(audiobookId: audiobook.id)
                        } label: {
                            Label("audiobook.view", systemImage: "book")
                        }
                        
                        if let author = audiobook.author {
                            Button(action: {
                                Task {
                                    if let authorId = try? await AudiobookshelfClient.shared.getAuthorId(name: author, libraryId: audiobook.libraryId) {
                                        Navigation.navigate(authorId: authorId)
                                    }
                                }
                            }) {
                                Label("author.view", systemImage: "person")
                                Text(author)
                            }
                        }
                        
                        if !audiobook.series.isEmpty {
                            if audiobook.series.count == 1, let series = audiobook.series.first {
                                Button(action: {
                                    Navigation.navigate(seriesName: series.name)
                                }) {
                                    Label("series.view", systemImage: "text.justify.leading")
                                    Text(series.name)
                                }
                            } else {
                                Menu {
                                    ForEach(audiobook.series, id: \.name) { series in
                                        Button(action: {
                                            Navigation.navigate(seriesName: series.name)
                                        }) {
                                            Text(series.name)
                                        }
                                    }
                                } label: {
                                    Label("series.view", systemImage: "text.justify.leading")
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    Menu {
                        ChapterMenu()
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
                    .padding(20)
                }
        }
    }
}
