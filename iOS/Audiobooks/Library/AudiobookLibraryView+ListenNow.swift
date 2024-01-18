//
//  AudiobookLibraryView+Home.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import SPBaseKit
import SPOfflineKit

extension AudiobookLibraryView {
    struct ListenNowView: View {
        @Environment(\.libraryId) var libraryId: String
        
        @State var audiobookRows = [AudiobookHomeRow]()
        @State var authorRows = [AuthorHomeRow]()
        
        @State var downloadedAudiobooks = [Audiobook]()
        
        @State var failed = false
        
        var body: some View {
            NavigationStack {
                Group {
                    if audiobookRows.isEmpty {
                        if failed {
                            ErrorView()
                        } else {
                            LoadingView()
                                .task(loadRows)
                        }
                    } else {
                        ScrollView {
                            VStack {
                                ForEach(audiobookRows) { row in
                                    if row.id != "discover" || !UserDefaults.standard.bool(forKey: "disableDiscoverRow") {
                                        AudiobooksRowContainer(title: row.label, audiobooks: row.audiobooks)
                                    }
                                }
                                
                                if !downloadedAudiobooks.isEmpty {
                                    AudiobooksRowContainer(title: "Downloaded", audiobooks: downloadedAudiobooks)
                                }
                                
                                if UserDefaults.standard.bool(forKey: "showAuthorsRow") {
                                    ForEach(authorRows) { row in
                                        AuthorTitleRow(title: row.label, authors: row.authors)
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("title.listenNow")
                .modifier(LibrarySelectorModifier())
                .modifier(NowPlayingBarSafeAreaModifier())
                .refreshable(action: loadRows)
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.home", systemImage: "bookmark.fill")
            }
        }
    }
}

extension AudiobookLibraryView.ListenNowView {
    @Sendable
    func loadRows() {
        Task.detached {
            do {
                (audiobookRows, authorRows) = try await AudiobookshelfClient.shared.getAudiobooksHome(libraryId: libraryId)
            } catch {
                failed = true
            }
        }
        
        Task.detached { @MainActor in
            downloadedAudiobooks = try OfflineManager.shared.getAudiobooks()
        }
    }
}
