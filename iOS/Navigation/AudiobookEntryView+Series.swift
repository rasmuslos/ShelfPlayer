//
//  AudiobookLibraryView+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import SPBase

extension AudiobookEntryView {
    struct SeriesView: View {
        @Environment(\.libraryId) var libraryId
        
        @State var failed = false
        @State var series = [Series]()
        
        var body: some View {
            NavigationStack {
                Group {
                    if series.isEmpty {
                        if failed {
                            ErrorView()
                        } else {
                            LoadingView()
                                .task { await fetchItems() }
                        }
                    } else {
                        ScrollView {
                            SeriesGrid(series: series)
                                .padding()
                        }
                        .modifier(NowPlayingBarSafeAreaModifier())
                    }
                }
                .navigationTitle("title.series")
                .navigationBarTitleDisplayMode(.large)
                .refreshable { await fetchItems() }
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.series", systemImage: "books.vertical.fill")
            }
        }
    }
}

// MARK: Helper

extension AudiobookEntryView.SeriesView {
    func fetchItems() async {
        failed = false
        
        if let series = try? await AudiobookshelfClient.shared.getSeries(libraryId: libraryId) {
            self.series = series
        } else {
            failed = true
        }
    }
}
