//
//  BookmarksList.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.05.25.
//

import SwiftUI
import ShelfPlayback

struct BookmarksList: View {
    @Environment(Satellite.self) private var satellite

    let itemID: ItemIdentifier
    let bookmarks: [Bookmark]

    @ViewBuilder
    private func row(for bookmark: Bookmark) -> some View {
        let time = TimeInterval(bookmark.time)

        TimeRow(title: bookmark.note, time: time, isActive: false, isFinished: false) {
            satellite.start(itemID, at: time)
        }
        .modifier(EditBookmarkSwipeAction(bookmark: bookmark))
    }

    var body: some View {
        ForEach(bookmarks) {
            row(for: $0)
        }
        .onDelete {
            guard let currentItemID = satellite.nowPlayingItemID else {
                return
            }

            for index in $0 {
                satellite.deleteBookmark(at: satellite.bookmarks[index].time, from: currentItemID)
            }
        }
    }
}

struct EditBookmarkSwipeAction: ViewModifier {
    @Environment(PlaybackViewModel.self) private var playbackViewModel
    @Environment(BookmarkEditor.self) private var bookmarkEditor

    let bookmark: Bookmark

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading) {
                Button("action.edit", systemImage: "pencil") {
                    Task {
                        if playbackViewModel.isExpanded {
                            playbackViewModel.toggleExpanded()
                            try await Task.sleep(for: .seconds(0.6))
                        }

                        bookmarkEditor.begin(at: bookmark.time, from: bookmark.itemID)
                    }
                }
                .tint(.accentColor)
            }
    }
}
