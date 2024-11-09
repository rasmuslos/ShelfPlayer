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

internal extension NowPlaying {
    struct ContextMenuModifier: ViewModifier {
        @Environment(\.library) private var library
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        private var offline: Bool {
            library.type == .offline
        }
        
        func body(content: Content) -> some View {
            content
                .contextMenu {
                    Group {
                        if let episode = viewModel.item as? Episode {
                            Button {
                                Navigation.navigate(episodeID: episode.id, podcastID: episode.podcastId, libraryID: episode.libraryID)
                            } label: {
                                Label("episode.view", systemImage: "play.square.stack")
                            }
                            
                            Button {
                                Navigation.navigate(podcastID: episode.podcastId, libraryID: episode.libraryID)
                            } label: {
                                Label("podcast.view", systemImage: "rectangle.stack")
                                Text(episode.podcastName)
                            }
                        }
                        
                        if let audiobook = viewModel.item as? Audiobook {
                            Button {
                                Navigation.navigate(audiobookID: audiobook.id, libraryID: audiobook.libraryID)
                            } label: {
                                Label("audiobook.view", systemImage: "book")
                            }
                            
                            if let authors = audiobook.authors {
                                AuthorMenu(authors: authors, libraryID: audiobook.libraryID)
                            }
                            
                            SeriesMenu(series: audiobook.series, libraryID: audiobook.libraryID)
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
                    
                    SleepTimerButton()
                    PlaybackSpeedButton()
                    
                    Divider()
                    
                    Button {
                        AudioPlayer.shared.skipBackwards()
                    } label: {
                        Label("backwards", systemImage: "gobackward.\(viewModel.skipBackwardsInterval)")
                    }
                    
                    Button {
                        AudioPlayer.shared.skipForwards()
                    } label: {
                        Label("forwards", systemImage: "goforward.\(viewModel.skipForwardsInterval)")
                    }
                    
                    Divider()
                    
                    Button {
                        AudioPlayer.shared.stop()
                    } label: {
                        Label("playback.stop", systemImage: "stop.fill")
                    }
                } preview: {
                    VStack(alignment: .leading, spacing: 2) {
                        ItemImage(cover: viewModel.item?.cover, aspectRatio: .none)
                            .padding(.bottom, 12)
                        
                        Group {
                            if let episode = viewModel.item as? Episode, let releaseDate = episode.releaseDate {
                                Text(releaseDate, style: .date)
                            } else if let audiobook = viewModel.item as? Audiobook, let seriesName = audiobook.seriesName {
                                Text(seriesName)
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        
                        if let name = viewModel.item?.name {
                            Text(name)
                                .font(.headline)
                        }
                        
                        if let author = viewModel.item?.author {
                            Text(author)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        if let audiobook = viewModel.item as? Audiobook, let narrator = audiobook.narrator {
                            Text("readBy \(narrator)")
                                .font(.subheadline)
                                .foregroundStyle(.tertiary)
                        }
                    }
                    .frame(width: 240)
                    .padding(20)
                }
        }
    }
}
