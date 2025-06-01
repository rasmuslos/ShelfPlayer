//
//  ChaptersList.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 21.05.25.
//

import SwiftUI
import ShelfPlayback

struct ChaptersList: View {
    @Environment(Satellite.self) private var satellite
    
    let itemID: ItemIdentifier
    let chapters: [Chapter]
    
    private var isPlaying: Bool {
        satellite.nowPlayingItemID == itemID
    }
    
    @ViewBuilder
    private func row(for chapter: Chapter) -> some View {
        TimeRow(title: chapter.title, time: chapter.startOffset, isActive: isPlaying && satellite.currentTime >= chapter.startOffset, isFinished: isPlaying && satellite.currentTime > chapter.endOffset) {
            satellite.start(itemID, at: chapter.startOffset)
        }
    }
    
    var body: some View {
        ForEach(chapters) {
            row(for: $0)
        }
    }
}

#if DEBUG
#Preview {
    List {
        ChaptersList(itemID: .fixture, chapters: [
            Chapter(id: 0, startOffset: 300, endOffset: 360, title: "Test"),
        ])
    }
    .listStyle(.plain)
    .previewEnvironment()
}
#endif
