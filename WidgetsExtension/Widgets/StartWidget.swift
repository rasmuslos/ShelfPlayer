//
//  PlayWidget.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.10.25.
//

import SwiftUI
import WidgetKit
import ShelfPlayerKit

struct StartWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "io.rfk.shelfPlayer.start", intent: StartWidgetConfiguration.self, provider: StartTimelineProvider()) {
            StartWidgetContent(entry: $0)
        }
        .configurationDisplayName(Text("widget.start"))
        .description(Text("widget.start.description"))
        .promptsForUserConfiguration()
        .supportedFamilies([
            .accessoryCircular,
            .systemSmall, .systemMedium
        ])
    }
}

struct StartWidgetTimelineEntry: TimelineEntry {
    let date: Date
    let relevance: TimelineEntryRelevance?
    
    let item: Item?
    
    let imageData: Data?
    let imageDataTiny: Data?
    
    let entity: ItemEntity?
    
    let isDownloaded: Bool
    let isPlaying: Bool?
    
    let progress: Percentage?
    
    init(date: Date = .now, item: Item?, isDownloaded: Bool, isPlaying: Bool?) {
        self.date = date
        
        relevance = TimelineEntryRelevance(score: 0)
        
        self.item = item
        
        imageData = nil
        imageDataTiny = nil
        
        entity = nil
        
        self.isDownloaded = isDownloaded
        self.isPlaying = isPlaying
        
        progress = nil
    }
    init(date: Date = .now, item: Item?, isDownloaded: Bool, isPlaying: Bool?, isStandalone: Bool = false) async {
        self.date = date
        
        if let isPlaying {
            let modifier: Float = isStandalone ? 2 : 1
            relevance = TimelineEntryRelevance(score: isPlaying ? 50 * modifier : 25 * modifier)
        } else {
            relevance = TimelineEntryRelevance(score: isStandalone ? 25 : 0)
        }
        
        self.item = item
        
        if let item {
            imageData = await Cache.shared.cover(for: item.id)
            imageDataTiny = await Cache.shared.cover(for: item.id, tiny: true)
            
            entity = await ItemEntity(item: item)
        } else {
            imageData = nil
            imageDataTiny = nil
            
            entity = nil
        }
        
        self.isDownloaded = isDownloaded
        self.isPlaying = isPlaying
        
        if let item, item.id.isPlayable {
            progress = await PersistenceManager.shared.progress[item.id].progress
        } else {
            progress = nil
        }
    }
}

struct StartTimelineProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> StartWidgetTimelineEntry {
        StartWidgetTimelineEntry(item: nil, isDownloaded: false, isPlaying: nil)
    }
    
    func snapshot(for configuration: StartWidgetConfiguration, in context: Context) async -> StartWidgetTimelineEntry {
        return await resolve(itemID: configuration.item?.id)
    }
    func timeline(for configuration: StartWidgetConfiguration, in context: Context) async -> Timeline<StartWidgetTimelineEntry> {
        let entry = await resolve(itemID: configuration.item?.id)
        return .init(entries: [entry], policy: configuration.item == nil ? .after(.now.advanced(by: 60 * 60 * 2)) : .never)
    }
    
    private func resolve(itemID: ItemIdentifier?) async -> StartWidgetTimelineEntry {
        var itemID = itemID
        
        if itemID == nil, let listenNowItems = Defaults[.playbackInfoWidgetValue]?.listenNowItems {
            itemID = listenNowItems.first?.id
        }
        
        guard let itemID else {
            return await .init(item: nil, isDownloaded: false, isPlaying: nil)
        }
        
        let isPlaying: Bool?
        let isDownloaded: Bool
        
        if let playbackInfoWidgetValue = Defaults[.playbackInfoWidgetValue], (playbackInfoWidgetValue.currentItemID == itemID || playbackInfoWidgetValue.currentItemID?.groupingID == itemID.primaryID) {
            isPlaying = playbackInfoWidgetValue.isPlaying
            isDownloaded = playbackInfoWidgetValue.isDownloaded
        } else {
            isPlaying = nil
            isDownloaded = false
        }
        
        return await StartWidgetTimelineEntry(item: try? itemID.resolved, isDownloaded: isDownloaded, isPlaying: isPlaying, isStandalone: true)
    }
}

struct StartWidgetContent: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.widgetFamily) var widgetFamily
    
    let entry: StartWidgetTimelineEntry
    
    private var name: String {
        guard let item = entry.item else {
            return "--"
        }
        
        return item.name
    }
    @ViewBuilder
    private func image(cornerRadius: CGFloat, tiny: Bool = false) -> some View {
        var imageData: Data? {
            if tiny {
                entry.imageDataTiny
            } else {
                entry.imageData
            }
        }
        
        Group {
            if let imageData, let image = UIImage(data: imageData) {
                Image(uiImage: image)
                    .resizable()
                    .widgetAccentedRenderingMode(.fullColor)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            } else {
                ItemImage(item: nil, size: .regular, cornerRadius: cornerRadius)
            }
        }
        .frame(width: 52)
    }
    
    @ViewBuilder
    private var label: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 0) {
                image(cornerRadius: 12)
                
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
                .transition(.move(edge: .leading))
            
            Spacer(minLength: 0)
            
            if entry.item != nil {
                HStack(spacing: 0) {
                    Group {
                        if entry.isPlaying == true {
                            Button(intent: SkipBackwardsIntent()) {
                                Label("skipBackwards", systemImage: "arrow.trianglehead.counterclockwise.rotate.90")
                                    .labelStyle(.iconOnly)
                            }
                            .padding(.trailing, 8)
                        }
                        
                        if widgetFamily == .systemSmall && entry.isPlaying == true {
                            WidgetItemButton(item: entry.item, isPlaying: entry.isPlaying, entity: entry.entity, progress: entry.progress)
                                .labelStyle(.iconOnly)
                        } else {
                            WidgetItemButton(item: entry.item, isPlaying: entry.isPlaying, entity: entry.entity, progress: entry.progress)
                                .labelStyle(.titleAndIcon)
                        }
                    }
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
            switch widgetFamily {
                case .accessoryCircular:
                    Group {
                        if let progress = entry.progress, let entity = entry.entity {
                            Button(intent: OpenIntent(item: entity)) {
                                Gauge(value: progress, in: 0...1) {
                                    Text(max(0.01, progress), format: .percent.notation(.compactName))
                                } currentValueLabel: {
                                    image(cornerRadius: 4, tiny: true)
                                        .padding(18)
                                }
                                .gaugeStyle(.accessoryCircular)
                            }
                            .buttonStyle(.plain)
                        } else {
                            Gauge(value: 0) {
                                Image("shelfPlayer.fill")
                            }
                            .gaugeStyle(.accessoryCircular)
                        }
                    }
                    .containerBackground(.clear, for: .widget)
                default:
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
        .animation(.smooth, value: entry.date)
    }
}

#if DEBUG
#Preview(as: .accessoryCircular) {
    StartWidget()
} timeline: {
    StartWidgetTimelineEntry(item: Podcast.fixture, isDownloaded: false, isPlaying: false)
}
#endif
