//
//  ListenNowWidget.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import WidgetKit
import SwiftUI
import Defaults
import ShelfPlayerKit

struct ListenNowWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "io.rfk.shelfPlayer.listenNow", provider: ListenNowWidgetProvider()) {
            ListenNowWidgetContent(entry: $0)
        }
        .configurationDisplayName(Text("widget.listenNow"))
        .description(Text("widget.listenNow.description"))
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

struct ListenNowWidgetProvider: TimelineProvider {
    func placeholder(in context: Context) -> ListenNowTimelineEntry {
        ListenNowTimelineEntry(playbackItem: nil, items: [], covers: [:])
    }
    func getSnapshot(in context: Context, completion: @Sendable @escaping (ListenNowTimelineEntry) -> Void) {
        Task {
            completion(await getCurrent())
        }
    }
    func getTimeline(in context: Context, completion: @Sendable @escaping (Timeline<ListenNowTimelineEntry>) -> Void) {
        Task {
            completion(Timeline(entries: [await getCurrent()], policy: .never))
        }
    }
    
    private func getCurrent() async -> ListenNowTimelineEntry {
        guard let items = Defaults[.listenNowWidgetItems]?.items else {
            return ListenNowTimelineEntry(playbackItem: nil, items: [], covers: [:])
        }
        
        let covers = await withTaskGroup {
            for item in items {
                $0.addTask {
                    (item.id, await item.id.data(size: .regular))
                }
            }
            
            return await $0.reduce(into: [:]) { $0[$1.0] = $1.1 }
        }
        
        let playbackItem: (ItemIdentifier, Bool)?
        
        if let lastListened = Defaults[.lastListened], let itemID = lastListened.item?.id, let isPlaying = lastListened.isPlaying {
            playbackItem = (itemID, isPlaying)
        } else {
            playbackItem = nil
        }
        
        return ListenNowTimelineEntry(playbackItem: playbackItem, items: items, covers: covers)
    }
}

struct ListenNowTimelineEntry: TimelineEntry {
    var date: Date = .now
    
    let playbackItem: (ItemIdentifier, Bool)?
    
    var items: [PlayableItem]
    var covers: [ItemIdentifier: Data]
}

private struct ListenNowWidgetContent: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) var widgetFamily
    
    @Default(.tintColor) private var tintColor
    
    let entry: ListenNowTimelineEntry
    
    private var rowCount: Int {
        switch widgetFamily {
            case .systemMedium:
                2
            case .systemLarge:
                6
            default:
                0
        }
    }
    private var items: [PlayableItem] {
        Array(entry.items.prefix(upTo: min(entry.items.endIndex, rowCount)))
    }
    
    @ViewBuilder
    private func row(item: PlayableItem) -> some View {
        HStack(spacing: 8) {
            if let imageData = entry.covers[item.id], let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                ItemImage(item: nil, size: .regular, cornerRadius: 8)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(item.name)
                    .bold()
                    .lineLimit(1)
                
                Text(item.authors, format: .list(type: .and))
                    .lineLimit(1)
            }
            .font(.caption)
            
            Spacer(minLength: 0)
            
            WidgetItemButton(item: item, isPlaying: entry.playbackItem?.0 == item.id ? entry.playbackItem?.1 : nil)
                .buttonStyle(.plain)
                .controlSize(.small)
                .labelStyle(.iconOnly)
                .padding(6)
                .foregroundStyle(colorScheme == .light ? .black : .white)
                .background(.ultraThinMaterial, in: .circle)
                .colorScheme(colorScheme == .dark ? .light : .dark)
                .font(.caption2)
        }
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                Text("widget.listenNow")
                    .font(.headline)
                
                Spacer(minLength: 8)
                
                Image("shelfPlayer.fill")
                    .foregroundStyle(colorScheme == .light ? .secondary : Color.white)
            }
            
            if entry.items.isEmpty {
                Spacer(minLength: 2)
                
                Text("widget.listenNow.empty")
                    .font(.footnote.smallCaps())
                    .foregroundStyle(.secondary)
            } else {
                ForEach(items) {
                    Spacer(minLength: 2)
                    row(item: $0)
                }
                
                let missing = rowCount - items.count
                
                if missing > 0 {
                    ForEach(0..<missing, id: \.hashValue) { _ in
                        row(item: Episode.placeholder)
                            .hidden()
                            .allowsHitTesting(false)
                    }
                }
            }
            
            Spacer(minLength: 2)
        }
        .containerBackground(for: .widget) {
            if colorScheme == .light {
                Rectangle()
                    .fill(tintColor.color.gradient)
            } else {
                Rectangle()
                    .fill(.background.secondary)
            }
        }
    }
}

#if DEBUG
#Preview(as: .systemMedium) {
    ListenNowWidget()
} timeline: {
    ListenNowTimelineEntry(playbackItem: (.fixture, true), items: [Audiobook.fixture], covers: [:])
    ListenNowTimelineEntry(playbackItem: (.fixture, false), items: [Audiobook.fixture, Episode.fixture], covers: [:])
}
#Preview(as: .systemLarge) {
    ListenNowWidget()
} timeline: {
    ListenNowTimelineEntry(playbackItem: (.fixture, false), items: [Audiobook.fixture], covers: [:])
    ListenNowTimelineEntry(playbackItem: (.fixture, true), items: [Audiobook.fixture, Episode.fixture, Episode.fixture, Audiobook.fixture, Audiobook.fixture, Episode.fixture], covers: [:])
}
#endif
