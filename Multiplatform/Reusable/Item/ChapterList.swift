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

struct ChaptersList: View {
    @Environment(\.defaultMinListRowHeight) private var minimumHeight
    
    let item: PlayableItem
    let chapters: [PlayableItem.Chapter]
    
    @State private var progressEntity: ItemProgress
    
    init(item: PlayableItem, chapters: [PlayableItem.Chapter]) {
        self.item = item
        self.chapters = chapters
        
        _progressEntity = .init(initialValue: OfflineManager.shared.progressEntity(item: item))
        progressEntity.beginReceivingUpdates()
    }
    
    var body: some View {
        if chapters.count > 1 {
            DisclosureGroup {
                List {
                    ForEach(chapters) {
                        Row(item: item, chapter: $0, progressEntity: progressEntity)
                    }
                }
                .listStyle(.plain)
                .frame(height: minimumHeight * CGFloat(chapters.count))
            } label: {
                Text("\(chapters.count) chapters")
                    .font(.headline)
            }
            .disclosureGroupStyle(ChapterDisclosureStyle())
        }
    }
}


private struct Row: View {
    let item: PlayableItem
    let chapter: PlayableItem.Chapter
    let progressEntity: ItemProgress
    
    @State private var loading = false
    @State private var errorNotify = false
    
    private var active: Bool {
        guard progressEntity.currentTime > 0 else {
            return false
        }
        
        return progressEntity.currentTime >= chapter.start && progressEntity.currentTime < chapter.end
    }
    private var finished: Bool {
        progressEntity.currentTime >= chapter.end
    }
    
    var body: some View {
        Button {
            Task {
                loading = true
                
                do {
                    if AudioPlayer.shared.item?.id == item.id {
                        await AudioPlayer.shared.seek(to: chapter.start)
                    } else {
                        try await AudioPlayer.shared.play(item, at: chapter.start)
                    }
                    
                    // :(
                    try await Task.sleep(nanoseconds: NSEC_PER_SEC)
                } catch {
                    errorNotify.toggle()
                }
                
                loading = false
            }
        } label: {
            HStack {
                Text(chapter.title)
                    .bold(active)
                    .foregroundStyle(finished ? .secondary : .primary)
                
                Spacer()
                
                if loading {
                    ProgressIndicator()
                        .scaleEffect(0.5)
                } else {
                    Text(chapter.start, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .foregroundStyle(.secondary)
                }
            }
            .lineLimit(1)
            .contentShape(.hoverMenuInteraction, .rect)
        }
        .sensoryFeedback(.error, trigger: errorNotify)
        .listRowInsets(.init(top: 8, leading: 0, bottom: 8, trailing: 0))
    }
    
}

private struct ChapterDisclosureStyle: DisclosureGroupStyle {
    func makeBody(configuration: Configuration) -> some View {
        VStack(spacing: 0) {
            Button {
                withAnimation {
                    configuration.isExpanded.toggle()
                }
            } label: {
                HStack {
                    configuration.label
                        .font(.headline)
                    
                    Spacer()
                    
                    Image(systemName: "chevron.down")
                        .font(.subheadline)
                        .rotationEffect(.degrees(configuration.isExpanded ? 0 : -90))
                        .animation(.linear, value: configuration.isExpanded)
                }
                .contentShape(.rect)
            }
            .buttonStyle(.plain)
            
            configuration.content
                .padding(.top, 8)
                .frame(maxHeight: configuration.isExpanded ? .infinity : 0, alignment: .top)
                .clipped()
        }
    }
}

#Preview {
    ScrollView {
        ChaptersList(item: Audiobook.fixture, chapters: [
            .init(id: 1, start: 0000, end: 1000, title: "Chapter 1 TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT TEXT"),
            .init(id: 2, start: 1001, end: 2000, title: "Chapter 2"),
            .init(id: 3, start: 2001, end: 3000, title: "Chapter 3"),
            .init(id: 4, start: 3001, end: 4000, title: "Chapter 4"),
            .init(id: 5, start: 4001, end: 5000, title: "Chapter 5"),
        ])
        .padding()
    }
}
