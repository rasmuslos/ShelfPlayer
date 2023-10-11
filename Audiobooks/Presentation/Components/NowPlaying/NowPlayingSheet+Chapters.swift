//
//  NowPlayingSheet+Chapters.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI

extension NowPlayingSheet {
    struct ChapterSheet: View {
        let item: PlayableItem
        let chapters = AudioPlayer.shared.chapters
        
        var body: some View {
            Group {
                if chapters.count > 1 {
                    List {
                        ForEach(chapters) {
                            ChapterRow(chapter: $0)
                        }
                    }
                } else {
                    VStack {
                        Spacer()
                        Text("No chapters")
                            .font(.headline.smallCaps())
                        Spacer()
                    }
                }
            }
            .listStyle(.plain)
            .safeAreaInset(edge: .top) {
                HStack {
                    ItemImage(image: item.image)
                    
                    VStack(alignment: .leading) {
                        Text(item.name)
                            .font(.headline)
                            .fontDesign(item as? Audiobook != nil ? .serif : .default)
                            .lineLimit(1)
                        
                        if let author = item.author {
                            Text(author)
                                .font(.subheadline)
                                .lineLimit(1)
                        }
                    }
                    
                    Spacer()
                }
                .padding()
                .background(.regularMaterial)
                .frame(height: 100)
            }
        }
    }
}

// MARK: Chapter

extension NowPlayingSheet.ChapterSheet {
    struct ChapterRow: View {
        let chapter: PlayableItem.Chapter
        
        var body: some View {
            Button {
                AudioPlayer.shared.seek(to: chapter.start)
            } label: {
                VStack(alignment: .leading) {
                    Text(chapter.title)
                    Text((chapter.end - chapter.start).hoursMinutesSecondsString(includeSeconds: true, includeLabels: false))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }
}
