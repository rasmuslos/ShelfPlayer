//
//  AudiobookView+Timeline.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

internal struct Timeline: View {
    let item: PlayableItem
    let sessions: [ListeningSession]
    
    private var released: String? {
        if let audiobook = item as? Audiobook {
            return audiobook.released
        } else if let episode = item as? Episode, let releaseDate = episode.releaseDate {
            return releaseDate.formatted(date: .abbreviated, time: .omitted)
        }
        
        return nil
    }
    
    var body: some View {
        LazyVStack(spacing: 52) {
            EventRow(date: .now, currentTime: 10, type: .end)
            
            ForEach(sessions) { session in
                VStack(spacing: 8) {
                    EventRow(date: session.endDate, currentTime: session.currentTime, type: .end)
                    
                    if let timeListening = session.timeListening {
                        HStack {
                            Text(timeListening, format: .duration(unitsStyle: .abbreviated, allowedUnits: [.hour, .minute]))
                                .font(.caption2)
                            
                            Spacer()
                        }
                    }
                    
                    EventRow(date: session.startDate, currentTime: session.startTime, type: .start)
                }
            }
            
            VStack(spacing: 16) {
                Row(date: item.addedAt, icon: "plus", color: .brown, text: .init("added \(item.addedAt.formatted(date: .numeric, time: .omitted))")) {
                    EmptyView()
                }
                
                if let released = released {
                    Row(date: .now, icon: "storefront", color: .green, hideTime: true, text: .init("released \(released)")) {
                        EmptyView()
                    }
                }
            }
        }
        .background(alignment: .leading) {
            HStack(spacing: 0) {
                Time(date: .now)
                    .hidden()
                
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 4, height: nil)
                    .padding(.leading, 10)
            }
        }
        .padding(.horizontal, 20)
    }
}

private struct EventRow: View {
    let date: Date
    let currentTime: TimeInterval
    let type: EventType
    
    var body: some View {
        Row(date: date, icon: type.icon, color: type.color) {
            Position(current: currentTime)
        }
    }
    
    enum EventType: Codable, Identifiable, Hashable {
        case start
        case end
        
        var id: Self {
            self
        }
        
        var icon: String {
            switch self {
                case .start:
                        "play.fill"
                case .end:
                        "pause.fill"
            }
        }
        var color: Color {
            switch self {
                case .start:
                        .accentColor
                case .end:
                        .primary
            }
        }
    }
}
private struct Row<Content: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    
    let date: Date
    let icon: String
    let color: Color
    
    var hideTime = false
    var text: Text? = nil
    
    @ViewBuilder var content: Content
    
    private var foreground: Color {
        if color == .primary && colorScheme == .dark {
            return .black
        }
        
        return color.isLight ? .black : .white
    }
    
    var body: some View {
        HStack(spacing: 0) {
            Time(date: date)
                .opacity(hideTime ? 0 : 1)
            
            Circle()
                .fill(color)
                .frame(width: 24)
                .overlay {
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundStyle(foreground)
                }
                .padding(.trailing, 12)
            
            if let text = text {
                text
            } else {
                Text(date, format: {
                    var formatStyle = Date.RelativeFormatStyle.relative(presentation: .named)
                    formatStyle.capitalizationContext = .listItem
                    
                    return formatStyle
                }())
            }
            
            Spacer(minLength: 8)
            
            content
        }
    }
}

private struct Time: View {
    let date: Date
    
    var body: some View {
        Text(date, format: .dateTime.hour().minute())
            .font(.caption2)
            .fontDesign(.monospaced)
            .foregroundStyle(.secondary)
            .padding(.trailing, 8)
    }
}
private struct Position: View {
    let current: TimeInterval
    
    var body: some View {
        Text(current, format: .duration(unitsStyle: .positional, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 3))
            .font(.caption)
            .fontDesign(.monospaced)
            .foregroundStyle(.secondary)
    }
}

#if DEBUG
#Preview {
    @Previewable @State var previewSessions: [ListeningSession] = []
    
    ScrollView {
        Timeline(item: Audiobook.fixture, sessions: previewSessions)
    }
    .task {
        do {
            previewSessions = try await AudiobookshelfClient.shared.listeningSessions(for: "0fbce99b-97af-4f6b-bb11-2a657b2fea86", episodeID: nil)
        } catch {
            print(error)
        }
    }
}
#endif
