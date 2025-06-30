//
//  AudiobookView+Timeline.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import ShelfPlayback

struct Timeline: View {
    @Environment(Satellite.self) private var satellite
    
    let sessionLoader: SessionLoader
    var item: PlayableItem? = nil
    
    private var isPlaying: Bool {
        satellite.nowPlayingItemID == item?.id
    }
    
    @ViewBuilder
    private func capsule<Content: View>(title: LocalizedStringKey, isLoading: Bool, @ViewBuilder text: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .top, spacing: 0) {
                text()
                    .bold()
                    .font(.title3)
                
                Spacer(minLength: 0)
                
                if isLoading {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(8)
        .background {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(.background.secondary)
        }
        .accessibilityElement(children: .combine)
    }
    
    @ViewBuilder
    private func row(text: Text, color: Color, systemImage: String) -> some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 26)
                
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(color.isLight == true ? .black : .white)
            }
            .padding(.trailing, 8)
            .accessibilityHidden(true)
            
            text
                .font(.caption)
            
            Spacer()
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if !sessionLoader.sessions.isEmpty || sessionLoader.isLoading {
                HStack(spacing: 12) {
                    capsule(title: "item.timeline.total",
                            isLoading: sessionLoader.isLoading) {
                        Text(sessionLoader.totalTimeSpendListening, format: .duration(unitsStyle: .full, allowedUnits: [.day, .hour, .minute], maximumUnitCount: 1))
                    }
                    
                    capsule(title: "item.lastPlayed", isLoading: sessionLoader.mostRecent == nil && sessionLoader.isLoading) {
                        if !isPlaying, let mostRecent = sessionLoader.mostRecent {
                            Text(mostRecent.startDate, style: .relative)
                        } else {
                            Text("loading")
                                .redacted(reason: .placeholder)
                        }
                    }
                }
            }
            
            LazyVStack(spacing: 20) {
                if isPlaying {
                    row(text: Text("item.timeline.playing"), color: .blue, systemImage: "pause.fill")
                }
                
                ForEach(sessionLoader.sessions) { session in
                    row(text: Text("item.timeline.row \(session.timeListening?.formatted(.duration(unitsStyle: .abbreviated, allowedUnits: [.day, .hour, .minute, .second], maximumUnitCount: 1)) ?? "?") \(session.startDate.formatted(.relative(presentation: .named)))"),
                        color: .accentColor,
                        systemImage: "play.fill")
                }
                
                if let audiobook = item as? Audiobook, let released = audiobook.released {
                    row(text: Text(verbatim: "item.released \(released)"), color: .green, systemImage: "plus")
                }
            }
            .background(alignment: .leading) {
                Rectangle()
                    .fill(Color.accentColor)
                    .frame(width: 2, height: nil)
                    .padding(.leading, 12)
            }
        }
        .onReceive(RFNotification[.playbackItemChanged].publisher()) { _ in
            sessionLoader.refresh()
        }
    }
}

private extension String {
    func leftPadding(toLength: Int, withPad character: Character) -> String {
        let stringLength = self.count
        if stringLength < toLength {
            return String(repeatElement(character, count: toLength - stringLength)) + self
        } else {
            return String(self.suffix(toLength))
        }
    }
}

#if DEBUG
#Preview {
    Timeline(sessionLoader: SessionLoader(filter: .fixture), item: Audiobook.fixture)
        .padding(20)
        .previewEnvironment()
}
#Preview {
    Timeline(sessionLoader: SessionLoader(filter: .itemID(.fixture)), item: Audiobook.fixture)
        .padding(20)
        .previewEnvironment()
}
#endif
