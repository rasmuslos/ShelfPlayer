//
//  NowPlayingSheet+Controls.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 10.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPPlayback

extension NowPlaying {
    struct Title: View {
        let item: PlayableItem
        let namespace: Namespace.ID
        
        @State private var bookmarkAnimation = false
        
        @State private var bookmarkNote = ""
        @State private var createBookmarkFailed = false
        @State private var bookmarkCapturedTime: Double? = nil
        @State private var createBookmarkAlertPresented = false
        
        var body: some View {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Group {
                        if let episode = item as? Episode, let releaseDate = episode.releaseDate {
                            Text(releaseDate, style: .date)
                                .matchedGeometryEffect(id: "releaseDate", in: namespace, properties: .frame, anchor: .top)
                        } else if let audiobook = item as? Audiobook, let seriesName = audiobook.seriesName {
                            Text(seriesName)
                        }
                    }
                    .font(.caption.smallCaps())
                    .foregroundStyle(.secondary)
                    
                    Group {
                        Text(item.name)
                            .font(.headline)
                            .fontDesign(item as? Audiobook != nil ? .serif : .default)
                            .foregroundStyle(.primary)
                            .matchedGeometryEffect(id: "title", in: namespace, properties: .frame, anchor: .top)
                        
                        if let author = item.author {
                            Menu {
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
                            } label: {
                                Text(author)
                                    .font(.subheadline)
                                    .lineLimit(1)
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .lineLimit(1)
                }
                
                Spacer()
                
                if item as? Audiobook != nil {
                    Label("bookmark.create", systemImage: "bookmark")
                        .labelStyle(.iconOnly)
                        .symbolEffect(.bounce.byLayer.up, value: bookmarkAnimation)
                        .onTapGesture {
                            createBookmarkFailed = false
                            bookmarkCapturedTime = AudioPlayer.shared.getItemCurrentTime()
                            createBookmarkAlertPresented = true
                        }
                        .onLongPressGesture {
                            Task {
                                await OfflineManager.shared.createBookmark(itemId: item.id, position: AudioPlayer.shared.getItemCurrentTime(), note: {
                                    let dateFormatter = DateFormatter()
                                    dateFormatter.locale = .autoupdatingCurrent
                                    dateFormatter.timeZone = .current
                                    
                                    dateFormatter.dateStyle = .medium
                                    dateFormatter.timeStyle = .medium
                                    
                                    return dateFormatter.string(from: .now)
                                }())
                                
                                bookmarkAnimation.toggle()
                            }
                        }
                        .font(.system(size: 20))
                        .foregroundStyle(createBookmarkFailed ? .red : .primary)
                        .alert("bookmark.create.alert", isPresented: $createBookmarkAlertPresented) {
                            TextField("bookmark.create.title", text: $bookmarkNote)
                            
                            Button {
                                createBookmark()
                                bookmarkAnimation.toggle()
                            } label: {
                                Text("bookmark.create.action")
                            }
                            Button(role: .cancel) {
                                createBookmarkAlertPresented = false
                            } label: {
                                Text("bookmark.create.cancel")
                            }
                        }
                        .popoverTip(CreateBookmarkTip())
                }
            }
        }
        
        private func createBookmark() {
            Task {
                if let bookmarkCapturedTime = bookmarkCapturedTime {
                    await OfflineManager.shared.createBookmark(itemId: item.id, position: bookmarkCapturedTime, note: bookmarkNote)
                }
            }
        }
    }
}
