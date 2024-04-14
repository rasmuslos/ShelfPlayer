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

extension NowPlayingViewModifier {
    struct Title: View {
        let item: PlayableItem
        let namespace: Namespace.ID
        
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
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    
                    Text(item.name)
                        .lineLimit(1)
                        .font(.headline)
                        .fontDesign(item as? Audiobook != nil ? .serif : .default)
                        .foregroundStyle(.primary)
                        .matchedGeometryEffect(id: "title", in: namespace, properties: .frame, anchor: .top)
                    
                    if let author = item.author {
                        Text(author)
                            .lineLimit(1)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                
                Spacer()
                
                if item as? Audiobook != nil {
                    Button {
                        createBookmarkFailed = false
                        bookmarkCapturedTime = AudioPlayer.shared.currentTime
                        createBookmarkAlertPresented = true
                    } label: {
                        Image(systemName: "bookmark")
                    }
                    .font(.system(size: 20))
                    .foregroundStyle(createBookmarkFailed ? .red : .primary)
                    .alert("bookmark.create.alert", isPresented: $createBookmarkAlertPresented) {
                        TextField("bookmark.create.title", text: $bookmarkNote)
                        
                        Button {
                            createBookmark()
                        } label: {
                            Text("bookmark.create.action")
                        }
                        Button(role: .cancel) {
                            createBookmarkAlertPresented = false
                        } label: {
                            Text("bookmark.create.cancel")
                        }
                    }
                }
            }
        }
    }
}

extension NowPlayingViewModifier.Title {
    func createBookmark() {
        Task {
            if let bookmarkCapturedTime = bookmarkCapturedTime {
                try await OfflineManager.shared.createBookmark(itemId: item.id, position: bookmarkCapturedTime, note: bookmarkNote)
            }
        }
    }
}
