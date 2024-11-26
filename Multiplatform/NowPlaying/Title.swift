//
//  NowPlayingSheet+Controls.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit
import SPPlayback

internal extension NowPlaying {
    struct Title: View {
        @Environment(\.library) private var library
        @Environment(NowPlaying.ViewModel.self) private var viewModel
        
        @Default(.useSerifFont) private var useSerifFont
        
        let item: PlayableItem
        
        private var isOffline: Bool {
            library.type == .offline
        }
        
        @ViewBuilder
        private var label: some View {
            VStack(alignment: .leading, spacing: 4) {
                Group {
                    if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                        Text(releaseDate, style: .date)
                    } else if let audiobook = item as? Audiobook, let seriesName = audiobook.seriesName {
                        Text(seriesName)
                    }
                }
                .font(.caption.smallCaps())
                .foregroundStyle(.secondary)
                
                Text(item.name)
                    .font(.headline)
                    .fontDesign(item.type == .audiobook && useSerifFont ? .serif : .default)
                    .foregroundStyle(.primary)
                
                if !item.authors.isEmpty {
                    Text(item.authors, format: .list(type: .and, width: .short))
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
            }
        }
        
        var body: some View {
            HStack {
                if isOffline {
                    label
                } else {
                    Menu {
                        if let episode = item as? Episode {
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
                        
                        if let audiobook = item as? Audiobook {
                            Button {
                                Navigation.navigate(audiobookID: audiobook.id, libraryID: audiobook.libraryID)
                            } label: {
                                Label("audiobook.view", systemImage: "book")
                            }
                            
                            AuthorMenu(authors: audiobook.authors, libraryID: audiobook.libraryID)
                            SeriesMenu(series: audiobook.series, libraryID: audiobook.libraryID)
                        }
                    } label: {
                        label
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer(minLength: 12)
                
                if item.type == .audiobook {
                    Label("bookmark.create", systemImage: "bookmark")
                        .labelStyle(.iconOnly)
                        .symbolEffect(.bounce.byLayer.up, value: viewModel.notifyBookmark)
                        .font(.system(size: 20))
                        .modifier(ButtonHoverEffectModifier())
                        .onTapGesture {
                            viewModel.presentBookmarkAlert()
                        }
                        .onLongPressGesture {
                            viewModel.createBookmark()
                        }
                }
            }
        }
    }
}
