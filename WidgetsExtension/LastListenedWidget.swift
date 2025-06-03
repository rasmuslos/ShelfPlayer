//
//  LastListenedWidget.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.05.25.
//

import WidgetKit
import SwiftUI
import ShelfPlayerKit

struct LastListenedWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "io.rfk.shelfPlayer.lastListened", provider: LastListenedWidgetProvider()) {
            LastListenedWidgetContent(entry: $0)
        }
        .configurationDisplayName(Text("widget.lastListened"))
        .description(Text("widget.lastListened.description"))
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct LastListenedWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> LastListenedWidgetTimelineEntry {
        LastListenedWidgetTimelineEntry(item: nil, isDownloaded: false, isPlaying: nil)
    }
    func getSnapshot(in context: Context, completion: @escaping @Sendable (LastListenedWidgetTimelineEntry) -> Void) {
        Task {
            completion(await getCurrent())
        }
    }
    func getTimeline(in context: Context, completion: @escaping @Sendable (Timeline<LastListenedWidgetTimelineEntry>) -> Void) {
        Task {
            completion(Timeline(entries: [await getCurrent()], policy: .never))
        }
    }
    
    private func getCurrent() async -> LastListenedWidgetTimelineEntry {
        guard let payload = Defaults[.playbackInfoWidgetValue] else {
            return await LastListenedWidgetTimelineEntry(item: nil, isDownloaded: false, isPlaying: nil)
        }
        
        return await LastListenedWidgetTimelineEntry(item: try? payload.currentItemID?.resolved as? PlayableItem, isDownloaded: payload.isDownloaded, isPlaying: payload.isPlaying)
    }
}

struct LastListenedWidgetTimelineEntry: TimelineEntry, Sendable {
    var date: Date = .now
    
    var item: PlayableItem?
    
    var imageData: Data?
    var entity: ItemEntity?
    
    var isDownloaded: Bool
    var isPlaying: Bool? = nil
    
    init(date: Date = .now, item: PlayableItem?, isDownloaded: Bool, isPlaying: Bool?) {
        self.date = date
        
        self.item = item
        
        imageData = nil
        entity = nil
        
        self.isDownloaded = isDownloaded
        self.isPlaying = isPlaying
    }
    init(date: Date = .now, item: PlayableItem?, isDownloaded: Bool, isPlaying: Bool?) async {
        self.date = date
        
        self.item = item
        
        if let item {
            imageData = await Cache.shared.cover(for: item.id)
            entity = await ItemEntity(item: item)
        } else {
            imageData = nil
            entity = nil
        }
        
        self.isDownloaded = isDownloaded
        self.isPlaying = isPlaying
    }
    
    var relevance: TimelineEntryRelevance? {
        if let isPlaying {
            TimelineEntryRelevance(score: isPlaying ? 0.5 : 0.25)
        } else {
            TimelineEntryRelevance(score: 0)
        }
    }
}

private struct LastListenedWidgetContent: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let entry: LastListenedWidgetTimelineEntry
    
    private var name: String {
        guard let item = entry.item else {
            return "--"
        }
        
        return item.name
    }
    @ViewBuilder
    private var image: some View {
        Group {
            if let imageData = entry.imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ItemImage(item: nil, size: .regular, cornerRadius: 8)
            }
        }
        .frame(width: 52)
    }
    
    @ViewBuilder
    private var label: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                image
                
                Spacer(minLength: 0)
                
                WidgetAppIcon()
            }
            
            Spacer(minLength: 0)
            
            Text(name)
                .bold()
                .font(.caption)
                .foregroundStyle(.ultraThickMaterial)
                .colorScheme(colorScheme == .light ? .dark : .light)
                .lineLimit(3)
            
            Spacer(minLength: 0)
            
            if entry.item != nil {
                HStack(spacing: 0) {
                    WidgetItemButton(item: entry.item, isPlaying: entry.isPlaying, entity: entry.entity)
                        .font(.footnote)
                        .controlSize(.small)
                        .tint(colorScheme == .light ? .black : .white)
                        .foregroundStyle(colorScheme == .light ? .black : .white)
                    
                    Spacer(minLength: 12)
                    
                    if entry.isDownloaded {
                        Image(systemName: "arrow.down.circle.fill")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .contentShape(.rect)
    }
    
    var body: some View {
        Group {
            if let entity = entry.entity {
                Button(intent: OpenIntent(item: entity)) {
                    label
                }
                .buttonStyle(.plain)
            } else {
                label
            }
        }
        .containerBackground(for: .widget) {
            WidgetBackground()
        }
    }
}

#if DEBUG
#Preview(as: .systemSmall) {
    LastListenedWidget()
} timeline: {
    LastListenedWidgetTimelineEntry(item: nil, isDownloaded: true, isPlaying: nil)
    LastListenedWidgetTimelineEntry(item: Audiobook.fixture, isDownloaded: false, isPlaying: true)
    LastListenedWidgetTimelineEntry(item: Audiobook.fixture, isDownloaded: true, isPlaying: false)
    LastListenedWidgetTimelineEntry(item: Episode.fixture, isDownloaded: true, isPlaying: true)
    LastListenedWidgetTimelineEntry(item: Episode.fixture, isDownloaded: false, isPlaying: false)
}
#Preview(as: .systemMedium) {
    LastListenedWidget()
} timeline: {
    LastListenedWidgetTimelineEntry(item: nil, isDownloaded: true, isPlaying: nil)
    LastListenedWidgetTimelineEntry(item: Audiobook.fixture, isDownloaded: true, isPlaying: true)
    LastListenedWidgetTimelineEntry(item: Audiobook.fixture, isDownloaded: false, isPlaying: false)
    LastListenedWidgetTimelineEntry(item: Episode.fixture, isDownloaded: false, isPlaying: true)
    LastListenedWidgetTimelineEntry(item: Episode.fixture, isDownloaded: true, isPlaying: false)
}
#endif
