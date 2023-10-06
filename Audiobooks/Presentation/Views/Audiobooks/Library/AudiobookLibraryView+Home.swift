//
//  AudiobookLibraryView+Home.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

extension AudiobookLibraryView {
    struct HomeView: View {
        @Environment(\.libraryId) var libraryId: String
        
        @State var audiobookRows: [AudiobookHomeRow]?
        @State var authorRows: [AuthorHomeRow]?
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack {
                        if let audiobookRows = audiobookRows {
                            ForEach(audiobookRows) { row in
                                AudiobooksRowContainer(title: row.label, audiobooks: row.audiobooks)
                            }
                        } else {
                            LoadingView()
                                .padding(.top, 50)
                        }
                    }
                }
                .navigationTitle("Listen now")
                .task(loadRows)
                .refreshable(action: loadRows)
            }
            .tabItem {
                Label("Listen now", systemImage: "bookmark.fill")
            }
        }
    }
}

// MARK: Helper

extension AudiobookLibraryView.HomeView {
    @Sendable
    func loadRows() {
        Task.detached {
            (audiobookRows, authorRows) = (try? await AudiobookshelfClient.shared.getAudiobooksHome(libraryId: libraryId)) ?? (nil, nil)
        }
    }
}
