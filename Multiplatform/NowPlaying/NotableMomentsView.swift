//
//  NowPlayingSheet+Chapters.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SwiftData
import Defaults
import SPBase
import SPOffline
import SPPlayback

extension NowPlaying {
    struct NotableMomentsView: View {
        @Default(.podcastNextUp) private var podcastNextUp
        
        let includeHeader: Bool
        @Binding var bookmarksActive: Bool
        
        @State private var bookmarks = [Bookmark]()
        
        private var empty: Bool {
            if bookmarksActive {
                return bookmarks.isEmpty
            } else {
                return AudioPlayer.shared.chapters.count <= 1
            }
        }
        
        private var currentChapter: PlayableItem.Chapter? {
            if Defaults[.enableChapterTrack] {
                return nil
            }
            
            return AudioPlayer.shared.chapters.first { $0.start < AudioPlayer.shared.currentTime && $0.end > AudioPlayer.shared.currentTime }
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
                                .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                Task {
                                    await OfflineManager.shared.deleteBookmark(bookmarks[index])
                                }
                            }
                        }
                    }
                    .mask(
                        VStack(spacing: 0) {
                            LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                                .frame(height: 40)
                            
                            Rectangle().fill(Color.black)
                            
                            LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                                .frame(height: 40)
                        }
                    )
                } else {
                    ScrollViewReader { proxy in
                        List {
                            ForEach(AudioPlayer.shared.chapters) {
                                ChapterRow(chapter: $0)
                                    .id($0.id)
                                    .listRowInsets(.init(top: 10, leading: 20, bottom: 10, trailing: 20))
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
                if podcastNextUp, let episode = AudioPlayer.shared.item as? Episode {
                    NextUp(episode: episode)
                } else if includeHeader {
                    HStack(spacing: 15) {
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
                                let speedAdjustment = (1 / Double(AudioPlayer.shared.playbackRate))
                                
                                if let currentChapter = currentChapter {
                                    Text(((currentChapter.end - AudioPlayer.shared.currentTime) * speedAdjustment).numericTimeLeft())
                                    + Text(verbatim: " ")
                                    + Text("\(currentChapter.title) chapter.remaining.in")
                                } else {
                                    let remaining = ((AudioPlayer.shared.getItemDuration() - AudioPlayer.shared.getItemCurrentTime()) * speedAdjustment).hoursMinutesSecondsString(includeSeconds: false, includeLabels: true)
                                    
                                    Text(remaining)
                                    + Text(verbatim: " ")
                                    + Text("time.left")
                                }
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        }
                        
                        Spacer()
                        
                        if AudioPlayer.shared.item as? Audiobook != nil {
                            Button {
                                bookmarksActive.toggle()
                            } label: {
                                Label("bookmarks.toggle", systemImage: "bookmark.square")
                                    .labelStyle(.iconOnly)
                                    .symbolVariant(bookmarksActive ? .fill : .none)
                            }
                            .font(.system(size: 26))
                            .foregroundStyle(.primary)
                            .popoverTip(ViewBookmarkTip())
                        }
                    }
                    .padding(20)
                    .background(.regularMaterial)
                    .frame(height: 100)
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: OfflineManager.bookmarksUpdatedNotification)) { _ in
                fetchBookmarks()
            }
            .onAppear {
                fetchBookmarks()
            }
        }
        
        @MainActor
        private func fetchBookmarks() {
            if let itemId = AudioPlayer.shared.item?.id, let bookmarks = try? OfflineManager.shared.getBookmarks(itemId: itemId) {
                self.bookmarks = bookmarks
            }
        }
    }
}

// MARK: Chapter

private extension NowPlaying {
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
                            Label("playing", systemImage: "waveform")
                                .labelStyle(.iconOnly)
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

// MARK: Next Up

private extension NowPlaying {
    struct NextUp: View {
        let episode: Episode
        
        @State private var next: Episode? = nil
        @State private var podcast: Podcast? = nil
        
        var body: some View {
            if let podcast = podcast, let next = next {
                HStack {
                    VStack(alignment: .leading, spacing: 15) {
                        Text("queue.nextUp: \(next.name)")
                            .font(.callout.smallCaps())
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                        
                        PodcastList.PodcastRow(podcast: podcast)
                    }
                    
                    Spacer()
                }
                .padding(.top, 15)
                .padding(.bottom, 15)
                .padding(.horizontal, 20)
                .frame(maxWidth: .infinity)
                .background(.regularMaterial)
            } else {
                Color.clear
                    .frame(height: 0)
                    .task {
                        if let (podcast, next) = await AudioPlayer.nextEpisode(podcastId: episode.podcastId) {
                            self.podcast = podcast
                            self.next = next
                        }
                    }
            }
        }
    }
}

#Preview {
    NowPlaying.NotableMomentsView(includeHeader: true, bookmarksActive: .constant(false))
}

#Preview {
    NowPlaying.NotableMomentsView(includeHeader: true, bookmarksActive: .constant(true))
}

#Preview {
    NowPlaying.NotableMomentsView(includeHeader: false, bookmarksActive: .constant(false))
}
