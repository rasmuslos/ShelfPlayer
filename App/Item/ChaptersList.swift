//
//  ChaptersList.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.05.25.
//

import SwiftUI
import ShelfPlayback

struct ChaptersList: View {
    @Environment(Satellite.self) private var satellite

    let itemID: ItemIdentifier
    let chapters: [Chapter]

    @State private var progress: ProgressTracker

    init(itemID: ItemIdentifier, chapters: [Chapter]) {
        self.itemID = itemID
        self.chapters = chapters

        _progress = .init(initialValue: .init(itemID: itemID))
    }

    private var currentTime: TimeInterval {
        progress.currentTime ?? 0
    }

    @ViewBuilder
    private func row(for chapter: Chapter) -> some View {
        TimeRow(title: chapter.title, time: chapter.startOffset, isActive: currentTime >= chapter.startOffset, isFinished: currentTime > chapter.endOffset) {
            satellite.start(itemID, at: chapter.startOffset)
        }
    }

    var body: some View {
        ForEach(chapters) {
            row(for: $0)
        }
    }
}
