//
//  SearchView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import SPBase

struct SearchView: View {
    @Environment(\.libraryId) var libraryId
    
    @State var query = ""
    @State var task: Task<(), Error>? = nil
    
    @State var audiobooks = [Audiobook]()
    @State var podcasts = [Podcast]()
    @State var authors = [Author]()
    @State var series = [Series]()
    
    @State var loading = false
    
    var body: some View {
        Group {
            if audiobooks.isEmpty && podcasts.isEmpty && series.isEmpty && authors.isEmpty {
                if loading {
                    LoadingView()
                } else {
                    ContentUnavailableView("search.empty.title", systemImage: "magnifyingglass", description: Text("search.empty.description"))
                }
            } else {
                List {
                    if !audiobooks.isEmpty {
                        Section("section.audiobooks") {
                            AudiobookList(audiobooks: audiobooks)
                        }
                    }
                    if !podcasts.isEmpty {
                        Section("section.podcasts") {
                            PodcastList(podcasts: podcasts)
                        }
                    }
                    
                    if !series.isEmpty {
                        Section("section.series") {
                            SeriesList(series: series)
                        }
                    }
                    
                    if !authors.isEmpty {
                        Section("section.authors") {
                            AuthorList(authors: authors)
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("title.search")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .modifier(NowPlayingBarSafeAreaModifier())
        .modifier(AccountSheetToolbarModifier(requiredSize: .compact))
        .onChange(of: query) {
            task?.cancel()
            task = Task.detached {
                loading = true
                
                if query == "" {
                    audiobooks = []
                    podcasts = []
                    authors = []
                    series = []
                } else {
                    (audiobooks, podcasts, authors, series) = try await AudiobookshelfClient.shared.getItems(query: query, libraryId: libraryId)
                }
                
                loading = false
            }
        }
    }
}

#Preview {
    SearchView()
}


#Preview {
    SearchView()
}
