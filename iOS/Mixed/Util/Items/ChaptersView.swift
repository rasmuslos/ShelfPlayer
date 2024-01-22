//
//  ChaptersView.swift
//  iOS
//
//  Created by Rasmus Krämer on 18.01.24.
//

import Foundation
import SwiftUI
import SPBase

struct ChaptersView: View {
    @Environment(\.defaultMinListRowHeight) var minimumHeight
    
    var chapters: PlayableItem.Chapters
    
    @State var expanded = false
    
    var body: some View {
        if chapters.count > 1 {
            DisclosureGroup(isExpanded: $expanded) {
                List {
                    ForEach(chapters) { chapter in
                        HStack {
                            Text(chapter.title)
                            Spacer()
                            Text((chapter.end - chapter.start).numericDuration())
                                .foregroundStyle(.secondary)
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
        }
    }
}

#Preview {
    ChaptersView(chapters: [
        .init(id: 1, start: 0000, end: 1000, title: "Chapter 1"),
        .init(id: 2, start: 1001, end: 2000, title: "Chapter 2"),
        .init(id: 3, start: 2001, end: 3000, title: "Chapter 3"),
        .init(id: 4, start: 3001, end: 4000, title: "Chapter 4"),
        .init(id: 5, start: 4001, end: 5000, title: "Chapter 5"),
    ])
    .border(.red)
    .padding()
}
