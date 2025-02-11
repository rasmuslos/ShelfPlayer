//
//  PodcastsRow.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct PodcastList: View {
    let podcasts: [Podcast]
    var onAppear: ((_ podcast: Podcast) -> Void)? = nil
    
    var body: some View {
        ForEach(podcasts) { podcast in
            PodcastRow(podcast: podcast)
                .onAppear {
                    onAppear?(podcast)
                }
        }
    }
}


private struct PodcastRow: View {
    @Environment(NamespaceWrapper.self) private var namespaceWrapper
    
    let podcast: Podcast
    
    private var author: String? {
        var result = [String]()
        
        if !podcast.authors.isEmpty {
            result.append(podcast.authors.formatted(.list(type: .and, width: .short)))
        }
        if let incompleteEpisodeCount = podcast.incompleteEpisodeCount {
            result.append(.init(localized: "\(incompleteEpisodeCount) episodes.unplayed"))
        }
        
        guard !result.isEmpty else {
            return nil
        }
        
        return result.joined(separator: " • ")
    }
    
    var body: some View {
        NavigationLink(destination: PodcastView(podcast, zoom: false)) {
            HStack(spacing: 0) {
                ItemImage(item: podcast)
                    .frame(width: 60)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(podcast.name)
                        .lineLimit(1)
                    
                    if let author {
                        Text(author)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
                .padding(.leading, 12)
            }
            .contentShape(.hoverMenuInteraction, .rect)
        }
        .listRowInsets(.init(top: 8, leading: 20, bottom: 8, trailing: 20))
    }
}


#if DEBUG
#Preview {
    @Previewable @Namespace var namespace
    
    NavigationStack {
        List {
            PodcastList(podcasts: .init(repeating: .fixture, count: 7))
        }
        .listStyle(.plain)
        .environment(NamespaceWrapper(namespace))
    }
}
#endif
