//
//  ChaptersView.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.01.24.
//

import Foundation
import SwiftUI
import SPFoundation
import SPPersistence
import SPPlayback

internal struct Chapters: View {
    let item: PlayableItem
    let chapters: [Chapter]
    
    @State private var progressEntity: ProgressEntity?
    
    private var activeIndex: Int? {
        /*
        guard progressEntity.currentTime > 0 else {
            return nil
        }
        
        return chapters.firstIndex { progressEntity.currentTime >= $0.startOffset && progressEntity.currentTime < $0.endOffset }
         */
        nil
    }
    private var finished: [Int] {
        var finished = [Int]()
        
        /*
        for chapter in chapters {
            if progressEntity.currentTime >= chapter.endOffset {
                finished.append(chapters.firstIndex(of: chapter)!)
            }
        }
         */
        
        return finished
    }
    
    init(item: PlayableItem, chapters: [Chapter]) {
        self.item = item
        self.chapters = chapters
        
        /*
        _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: item))
        progressEntity.beginReceivingUpdates()
         */
    }
    
    var body: some View {
        ForEach(Array(chapters.enumerated()), id: \.element.id) { (offset, chapter) in
            Row(id: "\(chapter.id)", title: chapter.title, time: chapter.startOffset, active: activeIndex == offset, finished: finished.contains { $0 == offset }) {
                /*
                if AudioPlayer.shared.item?.id == item.id {
                    await AudioPlayer.shared.seek(to: chapter.startOffset)
                } else {
                    try await AudioPlayer.shared.play(item, at: chapter.startOffset)
                }
                 */
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
                HStack(spacing: 0) {
                    ZStack {
                        Text(verbatim: "00:00:00")
                            .hidden()
                        
                        if loading {
                            ProgressIndicator()
                                .scaleEffect(0.5)
                        } else {
                            Text(time, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                        }
                    }
                    .font(.footnote)
                    .fontDesign(.rounded)
                    .foregroundStyle(Color.accentColor)
                    .padding(.trailing, 12)
                    
                    Text(title)
                        .bold(active)
                        .foregroundStyle(finished ? .secondary : .primary)
                    
                    Spacer(minLength: 0)
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
            .init(id: 1, startOffset: 0000, endOffset: 1000, title: "Chapter 1 TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT"),
            .init(id: 2, startOffset: 1001, endOffset: 2000, title: "Chapter 2"),
            .init(id: 3, startOffset: 2001, endOffset: 3000, title: "Chapter 3"),
            .init(id: 4, startOffset: 3001, endOffset: 4000, title: "Chapter 4"),
            .init(id: 5, startOffset: 4001, endOffset: 5000, title: "Chapter 5"),
        ])
    }
    .listStyle(.plain)
}
#endif
