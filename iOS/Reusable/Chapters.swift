//
//  ChaptersView.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.01.24.
//

import Foundation
import SwiftUI
import SPBase

struct ChaptersList: View {
    @Environment(\.defaultMinListRowHeight) var minimumHeight
    
    var chapters: PlayableItem.Chapters
    
    var body: some View {
        if chapters.count > 1 {
            DisclosureGroup {
                List {
                    ForEach(chapters) { chapter in
                        HStack {
                            Text(chapter.title)
                            Spacer()
                            Text((chapter.end - chapter.start).numericDuration())
                                .foregroundStyle(.secondary)
                        }
                        .listRowInsets(.init(top: 10, leading: 0, bottom: 10, trailing: 0))
                    }
                }
                .listStyle(.plain)
                .frame(height: minimumHeight * CGFloat(chapters.count))
            } label: {
                Text("\(chapters.count) chapters")
                    .font(.headline)
            }
            .foregroundStyle(.primary)
        }
    }
}

#Preview {
    ChaptersList(chapters: [
        .init(id: 1, start: 0000, end: 1000, title: "Chapter 1"),
        .init(id: 2, start: 1001, end: 2000, title: "Chapter 2"),
        .init(id: 3, start: 2001, end: 3000, title: "Chapter 3"),
        .init(id: 4, start: 3001, end: 4000, title: "Chapter 4"),
        .init(id: 5, start: 4001, end: 5000, title: "Chapter 5"),
    ])
    .padding()
}
