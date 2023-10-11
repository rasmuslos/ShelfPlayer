//
//  AudiobookLibraryView+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

extension AudiobookLibraryView {
    struct SeriesView: View {
        @Environment(\.libraryId) var libraryId
        
        @State var failed = false
        @State var series = [Series]()
        
        var body: some View {
            NavigationStack {
                Group {
                    if failed {
                        ErrorView()
                    } else if series.isEmpty {
                        LoadingView()
                    } else {
                        ScrollView {
                            SeriesGrid(series: series)
                                .padding()
                        }
                        .modifier(NowPlayingBarSafeAreaModifier())
                    }
                }
                .navigationTitle("Series")
                .navigationBarTitleDisplayMode(.large)
                .task(fetchAudiobooks)
                .refreshable(action: fetchAudiobooks)
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("Series", systemImage: "books.vertical.fill")
            }
        }
    }
}

// MARK: Helper

extension AudiobookLibraryView.SeriesView {
    @Sendable
    func fetchAudiobooks() {
        Task.detached {
            if let series = try? await AudiobookshelfClient.shared.getAllSeries(libraryId: libraryId) {
                self.series = series
            } else {
                failed = true
            }
        }
    }
}
