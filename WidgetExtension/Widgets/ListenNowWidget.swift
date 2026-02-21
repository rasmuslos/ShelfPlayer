//
//  ListenNowWidget.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.06.25.
//

import WidgetKit
import SwiftUI
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
        ListenNowTimelineEntry(playbackItem: nil, items: [], covers: [:], entities: [:])
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
        await OfflineMode.shared.ensureAvailabilityEstablished()
        
        let playbackItem: (ItemIdentifier, Bool)?
        
        if let payload = Defaults[.playbackInfoWidgetValue], let currentItemID = payload.currentItemID, let isPlaying = payload.isPlaying {
            playbackItem = (currentItemID, isPlaying)
        } else {
            playbackItem = nil
        }
        
        guard let items = try? await PersistenceManager.shared.listenNow.current else {
            return ListenNowTimelineEntry(playbackItem: playbackItem, items: [], covers: [:], entities: [:])
        }
        
        let itemIDs = items.map(\.id)
        async let covers = Cache.shared.covers(for: itemIDs, tiny: false)
        async let entities = Cache.shared.entities(for: itemIDs)
        
        return ListenNowTimelineEntry(playbackItem: playbackItem, items: items, covers: await covers, entities: await entities)
    }
}

struct ListenNowTimelineEntry: TimelineEntry {
    var date: Date = .now
    
    let playbackItem: (ItemIdentifier, Bool)?
    
    var items: [PlayableItem]
    
    var covers: [ItemIdentifier: Data]
    var entities: [ItemIdentifier: ItemEntity]
}

private struct ListenNowWidgetContent: View {
    @Environment(\.widgetRenderingMode) private var renderingMode
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) var widgetFamily
    
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
    private func label(item: PlayableItem) -> some View {
        if let imageData = entry.covers[item.id], let image = UIImage(data: imageData) {
            Image(uiImage: image)
                .resizable()
                .widgetAccentedRenderingMode(.fullColor)
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
    }
    @ViewBuilder
    private func row(item: PlayableItem) -> some View {
        HStack(spacing: 8) {
            if let entity = entry.entities[item.id] {
                Button(intent: OpenIntent(item: entity)) {
                    label(item: item)
                }
                .buttonStyle(.plain)
            } else {
                label(item: item)
            }
            
            Spacer(minLength: 0)
            
            WidgetItemButton(item: item, isPlaying: entry.playbackItem?.0 == item.id ? entry.playbackItem?.1 : nil, entity: entry.entities[item.id], progress: nil)
                .buttonStyle(.plain)
                .controlSize(.small)
                .labelStyle(.iconOnly)
                .padding(6)
                .foregroundStyle(colorScheme == .light ? .black : .white)
                .modify {
                    if renderingMode == .fullColor {
                        $0
                            .background(.ultraThinMaterial, in: .circle)
                    } else {
                        $0
                            .background(.green.opacity(0.2), in: .circle)
                    }
                }
                .colorScheme(colorScheme == .dark ? .light : .dark)
                .font(.caption2)
        }
        .contentShape(.rect)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack(spacing: 0) {
                Text("widget.listenNow")
                    .font(.headline)
                
                Spacer(minLength: 8)
                
                WidgetAppIcon()
            }
            
            if entry.items.isEmpty {
                Spacer(minLength: 0)
                
                Text("widget.listenNow.empty")
                    .font(.footnote.smallCaps())
                    .foregroundStyle(.secondary)
                
                Spacer(minLength: 0)
            } else {
                ForEach(items) { item in
                    Spacer(minLength: 2)
                    row(item: item)
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
        }
        .containerBackground(for: .widget) {
            WidgetBackground()
        }
    }
}

#if DEBUG
#Preview(as: .systemMedium) {
    ListenNowWidget()
} timeline: {
    ListenNowTimelineEntry(playbackItem: (.fixture, true), items: [Audiobook.fixture], covers: [:], entities: [:])
    ListenNowTimelineEntry(playbackItem: (.fixture, false), items: [Audiobook.fixture, Episode.fixture], covers: [:], entities: [:])
}
#Preview(as: .systemLarge) {
    ListenNowWidget()
} timeline: {
    ListenNowTimelineEntry(playbackItem: (.fixture, false), items: [Audiobook.fixture], covers: [:], entities: [:])
    ListenNowTimelineEntry(playbackItem: (.fixture, true), items: [Audiobook.fixture, Episode.fixture, Episode.fixture, Audiobook.fixture, Audiobook.fixture, Episode.fixture], covers: [:], entities: [:])
}
#endif
