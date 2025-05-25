//
//  AudiobookView+Timeline.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 30.08.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

struct Timeline: View {
    @Environment(Satellite.self) private var satellite
    
    let sessionLoader: SessionLoader
    var item: PlayableItem? = nil
    
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
    }
    
    @ViewBuilder
    private func row(title: String, text: Text, color: Color, systemImage: String) -> some View {
        HStack(spacing: 0) {
            Text(title.leftPadding(toLength: 5, withPad: " "))
                .font(.caption)
                .fontDesign(.monospaced)
                .lineLimit(1)
            
            ZStack {
                Circle()
                    .fill(color)
                    .frame(width: 26)
                
                Image(systemName: systemImage)
                    .font(.caption)
                    .foregroundStyle(color.isLight == true ? .black : .white)
            }
            .padding(.horizontal, 8)
            
            text
                .font(.caption)
            
            Spacer()
        }
    }
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                capsule(title: "loading", isLoading: false) {
                    Text(verbatim: "LAYOUT")
                }
                .hidden()
                
                if !sessionLoader.sessions.isEmpty || sessionLoader.isLoading {
                    HStack(spacing: 12) {
                        capsule(title: "item.timeline.total",
                                isLoading: sessionLoader.isLoading) {
                            Text(sessionLoader.totalTimeSpendListening, format: .duration(unitsStyle: .full, allowedUnits: [.day, .hour, .minute], maximumUnitCount: 1))
                        }
                        
                        capsule(title: "item.lastPlayed", isLoading: sessionLoader.mostRecent == nil && sessionLoader.isLoading) {
                            if let mostRecent = sessionLoader.mostRecent {
                                Text(mostRecent.startDate, style: .relative)
                            } else {
                                Text("loading")
                                    .redacted(reason: .placeholder)
                            }
                        }
                    }
                } else {
                    Text("item.timeline.empty")
                        .font(.caption.smallCaps())
                        .foregroundStyle(.secondary)
                }
            }
            
            LazyVStack(spacing: 20) {
                if satellite.nowPlayingItemID == item?.id {
                    row(title: "", text: Text("item.timeline.playing"), color: .blue, systemImage: "pause.fill")
                }
                
                ForEach(sessionLoader.sessions) { session in
                    row(title: session.timeListening?.formatted(.duration(unitsStyle: .abbreviated, allowedUnits: [.day, .hour, .minute], maximumUnitCount: 1)) ?? "?",
                        text: Text(session.startDate, style: .relative),
                        color: .accentColor,
                        systemImage: "play.fill")
                }
                
                if let audiobook = item as? Audiobook, let released = audiobook.released {
                    row(title: released, text: Text(verbatim: "item.released"), color: .green, systemImage: "plus")
                }
            }
            .background(alignment: .leading) {
                HStack(spacing: 0) {
                    Text(verbatim: "     ")
                        .font(.caption)
                        .fontDesign(.monospaced)
                        .hidden()
                        .padding(.trailing, 20)
                    
                    Rectangle()
                        .fill(Color.accentColor)
                        .frame(width: 2, height: nil)
                }
            }
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
#endif
