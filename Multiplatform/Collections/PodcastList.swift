//
//  PodcastsRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

struct PodcastList: View {
    let podcasts: [Podcast]
    let onAppear: ((_: Podcast) -> Void)
    
    var body: some View {
        ForEach(podcasts) { podcast in
            PodcastRow(podcast: podcast)
                .modifier(ItemStatusModifier(item: podcast))
                .onAppear {
                    onAppear(podcast)
                }
        }
    }
}


private struct PodcastRow: View {
    let podcast: Podcast
    
    private var subtitle: String? {
        var result = [String]()
        
        if !podcast.authors.isEmpty {
            result.append(podcast.authors.formatted(.list(type: .and, width: .short)))
        }
        if let incompleteEpisodeCount = podcast.incompleteEpisodeCount {
            result.append(.init(localized: "item.count.episodes.unplayed \(incompleteEpisodeCount)"))
        }
        
        guard !result.isEmpty else {
            return nil
        }
        
        return result.joined(separator: " • ")
    }
    
    var body: some View {
        NavigationLink(destination: PodcastView(podcast, zoom: false)) {
            HStack(spacing: 0) {
                ItemImage(item: podcast, size: .small)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(podcast.name)
                        .lineLimit(1)
                    
                    if let subtitle {
                        Text(subtitle)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 12)
            }
            .contentShape(.hoverMenuInteraction, .rect)
        }
        .buttonStyle(.plain)
        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}


#if DEBUG
#Preview {
    NavigationStack {
        List {
            PodcastList(podcasts: .init(repeating: .fixture, count: 7)) { _ in  }
        }
        .listStyle(.plain)
    }
    .previewEnvironment()
}
#endif
