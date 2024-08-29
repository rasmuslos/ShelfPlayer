//
//  NowPlayingBarContextMenuModifier.swift
//  iOS
//
//  Created by Rasmus Krämer on 10.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit
import SPPlayback

extension NowPlaying {
    struct ContextMenuModifier: ViewModifier {
        @Environment(\.libraryId) private var libraryId
        
        @Default(.skipBackwardsInterval) private var skipBackwardsInterval
        @Default(.skipForwardsInterval) private var skipForwardsInterval
        
        let item: PlayableItem
        
        @Binding var animateForwards: Bool
        
        private var offline: Bool {
            libraryId == "offline"
        }
        
        func body(content: Content) -> some View {
            content
                .contextMenu {
                    Group {
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
                                        if let authorId = try? await AudiobookshelfClient.shared.authorID(name: author, libraryId: audiobook.libraryId) {
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
                    }
                    .disabled(offline)
                    
                    Divider()
                    
                    Menu {
                        ChapterMenu()
                    } label: {
                        Label("chapters", systemImage: "list.dash")
                    }
                    
                    Divider()
                    
                    // SleepTimerButton()
                    PlaybackSpeedButton()
                    
                    Divider()
                    
                    Button {
                        AudioPlayer.shared.skipBackwards()
                    } label: {
                        Label("backwards", systemImage: "gobackward.\(skipBackwardsInterval)")
                    }
                    
                    Button {
                        animateForwards.toggle()
                        AudioPlayer.shared.skipForwards()
                    } label: {
                        Label("forwards", systemImage: "goforward.\(skipForwardsInterval)")
                    }
                    
                    Divider()
                    
                    Button {
                        AudioPlayer.shared.stop()
                    } label: {
                        Label("playback.stop", systemImage: "xmark")
                    }
                } preview: {
                    VStack(alignment: .leading) {
                        ItemImage(image: item.cover, aspectRatio: .none)
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
