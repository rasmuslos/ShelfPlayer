//
//  AudiobookLibraryView+Series.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import SPBaseKit

extension AudiobookLibraryView {
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
                .task(fetchAudiobooks)
                .refreshable(action: fetchAudiobooks)
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.series", systemImage: "books.vertical.fill")
            }
        }
    }
}

// MARK: Helper

extension AudiobookLibraryView.SeriesView {
    @Sendable
    func fetchAudiobooks() {
        Task.detached {
            if let series = try? await AudiobookshelfClient.shared.getSeries(libraryId: libraryId) {
                self.series = series
            } else {
                failed = true
            }
        }
    }
}
