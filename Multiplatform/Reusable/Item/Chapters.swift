//
//  ChaptersView.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.01.24.
//

import Foundation
import SwiftUI
import SPBase
import SPOffline
import SPPlayback

struct ChaptersList: View {
    @Environment(\.defaultMinListRowHeight) private var minimumHeight
    
    let item: PlayableItem
    let chapters: PlayableItem.Chapters
    
    @State private var entity: ItemProgress? = nil
    
    var body: some View {
        if chapters.count > 1 {
            DisclosureGroup {
                List {
                    if let entity = entity {
                        ForEach(chapters) {
                            Row(item: item, chapter: $0, entity: entity)
                        }
                    }
                }
                .listStyle(.plain)
                .frame(height: minimumHeight * CGFloat(chapters.count))
            } label: {
                Text("\(chapters.count) chapters")
                    .font(.headline)
            }
            .foregroundStyle(.primary)
            .task {
                entity = OfflineManager.shared.requireProgressEntity(item: item)
            }
        }
    }
}

private extension ChaptersList {
    struct Row: View {
        let item: PlayableItem
        let chapter: PlayableItem.Chapter
        let entity: ItemProgress
        
        private var active: Bool {
            entity.currentTime >= chapter.start && entity.currentTime < chapter.end
        }
        private var finished: Bool {
            entity.currentTime >= chapter.end
        }
        
        var body: some View {
            Button {
                item.startPlayback()
                
                Task {
                    try await Task.sleep(nanoseconds: UInt64(2 * TimeInterval(NSEC_PER_SEC)))
                    await AudioPlayer.shared.seek(to: chapter.start)
                }
            } label: {
                HStack {
                    Text(chapter.title)
                        .foregroundStyle(finished ? .secondary : .primary)
                        .bold(active)
                    
                    Spacer()
                    
                    Text((chapter.end - chapter.start).numericDuration())
                        .foregroundStyle(.secondary)
                }
                .contentShape(.hoverMenuInteraction, Rectangle())
            }
            .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
        }
    }
}

#Preview {
    ChaptersList(item: Audiobook.fixture, chapters: [
        .init(id: 1, start: 0000, end: 1000, title: "Chapter 1"),
        .init(id: 2, start: 1001, end: 2000, title: "Chapter 2"),
        .init(id: 3, start: 2001, end: 3000, title: "Chapter 3"),
        .init(id: 4, start: 3001, end: 4000, title: "Chapter 4"),
        .init(id: 5, start: 4001, end: 5000, title: "Chapter 5"),
    ])
    .padding()
}
