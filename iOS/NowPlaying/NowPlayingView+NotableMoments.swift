//
//  NowPlayingSheet+Chapters.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SwiftData
import SPBase
import SPOffline
import SPPlayback

extension NowPlayingViewModifier {
    struct NotableMomentsSheet: View {
        @State private var bookmarks = [Bookmark]()
        @State private var bookmarksActive = false
        
        private var empty: Bool {
            if bookmarksActive {
                return bookmarks.isEmpty
            } else {
                return AudioPlayer.shared.chapters.count <= 1
            }
        }
        
        var body: some View {
            Group {
                if empty {
                    VStack {
                        Spacer()
                        Text(bookmarksActive ? "bookmarks.empty" : "chapters.empty")
                            .font(.headline.smallCaps())
                        Spacer()
                    }
                } else if bookmarksActive {
                    List {
                        ForEach(bookmarks) {
                            BookmarkRow(bookmark: $0)
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                Task {
                                    await OfflineManager.shared.deleteBookmark(bookmarks[index])
                                }
                            }
                        }
                    }
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(AudioPlayer.shared.chapters) {
                                ChapterRow(chapter: $0)
                                    .id($0.id)
                            }
                        }
                        .onAppear {
                            proxy.scrollTo(AudioPlayer.shared.chapter?.id, anchor: .center)
                        }
                    }
                }
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top) {
                HStack {
                    ItemImage(image: AudioPlayer.shared.item?.image)
                    
                    VStack(alignment: .leading) {
                        Text(AudioPlayer.shared.item?.name ?? "-/-")
                            .font(.headline)
                            .fontDesign(AudioPlayer.shared.item as? Audiobook != nil ? .serif : .default)
                            .lineLimit(1)
                        
                        if let author = AudioPlayer.shared.item?.author {
                            Text(author)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                        
                        Group {
                            Text(
                                ((AudioPlayer.shared.getItemDuration() - AudioPlayer.shared.getItemCurrentTime()) * (1 / Double(AudioPlayer.shared.playbackRate)))
                                    .hoursMinutesSecondsString(includeSeconds: false, includeLabels: true)) + Text(verbatim: " ")
                            + Text("time.left")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }
                    
                    Spacer()
                    
                    if AudioPlayer.shared.item as? Audiobook != nil {
                        Button {
                            bookmarksActive.toggle()
                        } label: {
                            Image(systemName: "bookmark.square")
                                .symbolVariant(bookmarksActive ? .fill : .none)
                        }
                        .font(.system(size: 26))
                        .foregroundStyle(.primary)
                        .popoverTip(ViewBookmarkTip())
                    }
                }
                .padding()
                .background(.regularMaterial)
                .frame(height: 100)
            }
            .onReceive(NotificationCenter.default.publisher(for: OfflineManager.bookmarksUpdatedNotification)) { _ in
                fetchBookmarks()
            }
            .onAppear {
                fetchBookmarks()
            }
        }
    }
}

private extension NowPlayingViewModifier.NotableMomentsSheet {
    @MainActor
    func fetchBookmarks() {
        if let itemId = AudioPlayer.shared.item?.id, let bookmarks = try? OfflineManager.shared.getBookmarks(itemId: itemId) {
            self.bookmarks = bookmarks
        }
    }
}

// MARK: Chapter

private extension NowPlayingViewModifier.NotableMomentsSheet {
    struct ChapterRow: View {
        @Environment(\.dismiss) private var dismiss
        
        let chapter: PlayableItem.Chapter
        
        private var active: Bool {
            AudioPlayer.shared.chapter == chapter
        }
        
        var body: some View {
            Button {
                AudioPlayer.shared.seek(to: chapter.start)
                dismiss()
            } label: {
                VStack(alignment: .leading) {
                    Text((chapter.end - chapter.start).hoursMinutesSecondsString(includeSeconds: true, includeLabels: false))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    HStack {
                        Text(chapter.title)
                            .bold(active)
                        
                        Spacer()
                        
                        if active {
                            Image(systemName: "waveform")
                                .symbolEffect(.variableColor.iterative.dimInactiveLayers)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .transition(.opacity)
                        }
                    }
                    .overlay(alignment: .leadingFirstTextBaseline) {
                        if active {
                            Circle()
                                .foregroundStyle(.gray.opacity(0.3))
                                .frame(width: 7, height: 7)
                                .offset(x: -13)
                                .transition(.opacity)
                        }
                    }
                }
            }
        }
    }
}

// MARK: Bookmark

private extension NowPlayingViewModifier.NotableMomentsSheet {
    struct BookmarkRow: View {
        @Environment(\.dismiss) private var dismiss
        
        let bookmark: Bookmark
        
        var body: some View {
            Button {
                AudioPlayer.shared.seek(to: bookmark.position)
                dismiss()
            } label: {
                HStack {
                    VStack(alignment: .leading) {
                        Text(bookmark.position.hoursMinutesSecondsString(includeSeconds: true, includeLabels: false))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        
                        Text(bookmark.note)
                    }
                    
                    Spacer()
                }
            }
        }
    }
}
