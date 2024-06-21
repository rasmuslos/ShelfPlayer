//
//  SearchView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 14.10.23.
//

import SwiftUI
import SPBase

internal struct SearchView: View {
    @Environment(\.libraryId) private var libraryId
    
    @State private var query = ""
    @State private var task: Task<(), Error>? = nil
    
    @State private var audiobooks = [Audiobook]()
    @State private var podcasts = [Podcast]()
    @State private var authors = [Author]()
    @State private var series = [Series]()
    
    @State private var loading = false
    
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
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("title.search")
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always))
        .modifier(NowPlaying.SafeAreaModifier())
        .modifier(AccountSheetToolbarModifier(requiredSize: .compact))
        .onChange(of: query) {
            task?.cancel()
            task = Task {
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
