//
//  ChaptersView.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.01.24.
//

import Foundation
import SwiftUI
import SPFoundation
import SPOffline
import SPPlayback

internal struct Chapters: View {
    let item: PlayableItem
    let chapters: [PlayableItem.Chapter]
    
    @State private var progressEntity: ItemProgress
    
    private var activeIndex: Int? {
        guard progressEntity.currentTime > 0 else {
            return nil
        }
        
        return chapters.firstIndex { progressEntity.currentTime >= $0.start && progressEntity.currentTime < $0.end }
    }
    private var finished: [Int] {
        var finished = [Int]()
        
        for chapter in chapters {
            if progressEntity.currentTime >= chapter.end {
                finished.append(chapters.firstIndex(of: chapter)!)
            }
        }
        
        return finished
    }
    
    init(item: PlayableItem, chapters: [PlayableItem.Chapter]) {
        self.item = item
        self.chapters = chapters
        
        _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: item))
        progressEntity.beginReceivingUpdates()
    }
    
    var body: some View {
        ForEach(Array(chapters.enumerated()), id: \.element.id) { (offset, chapter) in
            Row(id: "\(chapter.id)", title: chapter.title, time: chapter.start, active: activeIndex == offset, finished: finished.contains { $0 == offset }) {
                if AudioPlayer.shared.item?.id == item.id {
                    await AudioPlayer.shared.seek(to: chapter.start)
                } else {
                    try await AudioPlayer.shared.play(item, at: chapter.start)
                }
            }
        }
    }
}

internal extension Chapters {
    struct Row: View {
        let id: String
        let title: String
        let time: TimeInterval
        
        let active: Bool
        let finished: Bool
        
        let callback: () async throws -> Void
        
        @State private var loading = false
        @State private var errorNotify = false
        
        var body: some View {
            Button {
                Task {
                    loading = true
                    
                    do {
                        try await callback()
                        
                        // :(
                        try await Task.sleep(nanoseconds: NSEC_PER_SEC)
                    } catch {
                        errorNotify.toggle()
                    }
                    
                    loading = false
                }
            } label: {
                HStack {
                    Text(title)
                        .bold(active)
                        .foregroundStyle(finished ? .secondary : .primary)
                    
                    Spacer()
                    
                    if loading {
                        ProgressIndicator()
                            .scaleEffect(0.5)
                    } else {
                        Text(time, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                            .font(.caption)
                            .fontDesign(.monospaced)
                            .foregroundStyle(.secondary)
                    }
                }
                .lineLimit(1)
                .contentShape(.hoverMenuInteraction, .rect)
            }
            .buttonStyle(.plain)
            .sensoryFeedback(.error, trigger: errorNotify)
            .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
            .id(id)
        }
    }
}

#if DEBUG
#Preview {
    List {
        Chapters(item: Audiobook.fixture, chapters: [
            .init(id: 1, start: 0000, end: 1000, title: "Chapter 1 TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT"),
            .init(id: 2, start: 1001, end: 2000, title: "Chapter 2"),
            .init(id: 3, start: 2001, end: 3000, title: "Chapter 3"),
            .init(id: 4, start: 3001, end: 4000, title: "Chapter 4"),
            .init(id: 5, start: 4001, end: 5000, title: "Chapter 5"),
        ])
    }
}
#endif
