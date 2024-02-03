//
//  AudiobookLibraryView+Home.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import Defaults
import SPBase
import SPOffline

extension AudiobookEntryView {
    struct ListenNowView: View {
        @Environment(\.libraryId) var libraryId: String
        
        @Default(.showAuthorsRow) var showAuthorsRow
        @Default(.disableDiscoverRow) var disableDiscoverRow
        
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
                                .task{ await fetchItems() }
                        }
                    } else {
                        ScrollView {
                            VStack {
                                ForEach(audiobookRows) { row in
                                    if row.id != "discover" || !disableDiscoverRow {
                                        VStack(alignment: .leading) {
                                            RowTitle(title: row.label)
                                            AudiobookHGrid(audiobooks: row.audiobooks)
                                        }
                                    }
                                }
                                
                                if !downloadedAudiobooks.isEmpty {
                                    VStack(alignment: .leading) {
                                        RowTitle(title: String(localized: "downloads"))
                                        AudiobookHGrid(audiobooks: downloadedAudiobooks)
                                    }
                                }
                                
                                if showAuthorsRow {
                                    ForEach(authorRows) { row in
                                        VStack(alignment: .leading) {
                                            RowTitle(title: row.label)
                                            AuthorGrid(authors: row.authors)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
                .navigationTitle("title.listenNow")
                .modifier(LibrarySelectorModifier())
                .modifier(NowPlayingBarSafeAreaModifier())
                .refreshable { await fetchItems() }
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.home", systemImage: "bookmark.fill")
            }
        }
    }
}

extension AudiobookEntryView.ListenNowView {
    func fetchItems() async {
        failed = false
        
        if let downloadedAudiobooks = try? OfflineManager.shared.getAudiobooks() {
            self.downloadedAudiobooks = downloadedAudiobooks
        }
        
        do {
            (audiobookRows, authorRows) = try await AudiobookshelfClient.shared.getAudiobooksHome(libraryId: libraryId)
        } catch {
            failed = true
        }
    }
}
