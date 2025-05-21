//
//  BookmarksList.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 21.05.25.
//

import SwiftUI
import ShelfPlayerKit

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

#if DEBUG
#Preview {
    List {
        BookmarksList(itemID: .fixture, bookmarks: [
            Bookmark(itemID: .fixture, time: 300, note: "Test", created: .now),
        ])
    }
    .listStyle(.plain)
    .previewEnvironment()
}
#endif
