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
                            Text(author)
                                .font(.subheadline)
                                .lineLimit(1)
                                .foregroundStyle(.secondary)
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
