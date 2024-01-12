//
//  AudiobookLibraryView+Home.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import ShelfPlayerKit

extension AudiobookLibraryView {
    struct HomeView: View {
        @Environment(\.libraryId) var libraryId: String
        
        @State var audiobookRows: [AudiobookHomeRow]?
        @State var authorRows: [AuthorHomeRow]?
        
        @State var downloadedAudiobooks = [Audiobook]()
        
        var body: some View {
            NavigationStack {
                ScrollView {
                    VStack {
                        if let audiobookRows = audiobookRows {
                            ForEach(audiobookRows) { row in
                                if row.id != "discover" || !UserDefaults.standard.bool(forKey: "disableDiscoverRow") {
                                    AudiobooksRowContainer(title: row.label, audiobooks: row.audiobooks)
                                }
                            }
                            
                            if !downloadedAudiobooks.isEmpty {
                                AudiobooksRowContainer(title: "Downloaded", audiobooks: downloadedAudiobooks)
                            }
                        } else {
                            LoadingView()
                                .padding(.top, 50)
                        }
                        
                        if UserDefaults.standard.bool(forKey: "showAuthorsRow"), let authorRows = authorRows{
                            ForEach(authorRows) { row in
                                AuthorTitleRow(title: row.label, authors: row.authors)
                            }
                        }
                    }
                }
                .navigationTitle("title.home")
                .modifier(LibrarySelectorModifier())
                .modifier(NowPlayingBarSafeAreaModifier())
                .task(loadRows)
                .refreshable(action: loadRows)
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.home", systemImage: "bookmark.fill")
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
        Task.detached {
            downloadedAudiobooks = await OfflineManager.shared.getAudiobooks()
        }
    }
}
