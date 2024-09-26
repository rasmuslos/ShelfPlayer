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
        
        private var offline: Bool {
            library.type == .offline
        }
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                        } else if let audiobook = item as? Audiobook, let seriesName = audiobook.seriesName {
                            if audiobook.series.count == 0, let series = audiobook.series.first {
                                NavigationLink(destination: SeriesLoadView(series: series)) {
                                    Text(seriesName)
                                        .lineLimit(1)
                                }
                                .buttonStyle(.plain)
                            } else {
                                Menu {
                                    ForEach(audiobook.series, id: \.name) { series in
                                        NavigationLink(destination: SeriesLoadView(series: series)) {
                                            Text(series.name)
                                        }
                                    }
                                } label: {
                                    Text(seriesName)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .font(.caption.smallCaps())
                    .foregroundStyle(.secondary)
                    
                    Text(item.name)
                        .font(.headline)
                        .fontDesign(item.type == .audiobook && useSerifFont ? .serif : .default)
                        .foregroundStyle(.primary)
                    
                    if let author = item.author {
                        Menu {
                            if let episode = item as? Episode {
                                Button {
                                    Navigation.navigate(episodeID: episode.id, podcastID: episode.podcastId, libraryID: episode.libraryID)
                                } label: {
                                    Label("episode.view", systemImage: "play.square.stack")
                                }
                                
                                Button(action: {
                                    Navigation.navigate(podcastID: episode.podcastId, libraryID: episode.libraryID)
                                }) {
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
                                 
                                if let author = audiobook.author {
                                    Button {
                                        Task {
                                            if let authorID = try? await AudiobookshelfClient.shared.authorID(name: author, libraryID: audiobook.libraryID) {
                                                Navigation.navigate(authorID: authorID, libraryID: audiobook.libraryID)
                                            }
                                        }
                                    } label: {
                                        Label("author.view", systemImage: "person")
                                    }
                                }
                                
                                if !audiobook.series.isEmpty {
                                    if audiobook.series.count == 1, let series = audiobook.series.first {
                                        Button {
                                            Navigation.navigate(seriesName: series.name, libraryID: audiobook.libraryID)
                                        } label: {
                                            Label("series.view", systemImage: "rectangle.grid.2x2.fill")
                                            Text(series.name)
                                        }
                                    } else {
                                        Menu {
                                            ForEach(audiobook.series, id: \.name) { series in
                                                Button {
                                                    Navigation.navigate(seriesName: series.name, libraryID: audiobook.libraryID)
                                                } label: {
                                                    Text(series.name)
                                                }
                                            }
                                        } label: {
                                            Label("series.view", systemImage: "rectangle.grid.2x2.fill")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Text(author)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .disabled(offline)
                    }
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
