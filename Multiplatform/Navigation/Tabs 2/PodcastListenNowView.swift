//
//  PodcastListenNowView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.04.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct PodcastListenNowView: View {
    @Environment(\.libraryId) private var libraryId: String
    @Default(.hideFromContinueListening) private var hideFromContinueListening
    
    @State var episodeRows = [HomeRow<Episode>]()
    @State var podcastRows = [HomeRow<Podcast>]()
    
    @State var failed = false
    
    var body: some View {
        Group {
            if episodeRows.isEmpty && podcastRows.isEmpty {
                if failed {
                    ErrorView()
                } else {
                    LoadingView()
                        .padding(.top, 50)
                        .task{ await fetchItems() }
                }
            } else {
                ScrollView {
                    VStack {
                        ForEach(episodeRows) { row in
                            VStack(alignment: .leading) {
                                RowTitle(title: row.label)
                                    .padding(.horizontal, 20)
                                
                                if row.id == "continue-listening" {
                                    EpisodeFeaturedGrid(episodes: row.entities.filter { episode in
                                        !hideFromContinueListening.contains { $0.itemId == episode.podcastId && $0.episodeId == episode.id }
                                    })
                                } else {
                                    EpisodeGrid(episodes: row.entities)
                                }
                            }
                        }
                        
                        ForEach(podcastRows) { row in
                            VStack(alignment: .leading) {
                                RowTitle(title: row.label)
                                    .padding(.horizontal, 20)
                                
                                PodcastHGrid(podcasts: row.entities)
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("title.listenNow")
        .modifier(NowPlaying.SafeAreaModifier())
        .refreshable { await fetchItems() }
    }
}

extension PodcastListenNowView {
    func fetchItems() async {
        failed = false
        
        do {
            // (episodeRows, podcastRows) = try await AudiobookshelfClient.shared.home(libraryId: libraryId)
        } catch {
            failed = true
        }
    }
}


#Preview {
    PodcastListenNowView()
}
