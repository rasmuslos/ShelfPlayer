//
//  AudiobookLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import SPBaseKit

extension AudiobookLibraryView {
    struct LibraryView: View {
        @Environment(\.libraryId) var libraryId
        
        @State var failed = false
        @State var audiobooks = [Audiobook]()
        @State var displayOrder = AudiobooksFilterSort.getDisplayType()
        @State var filter = AudiobooksFilterSort.getFilter()
        @State var sortOrder = AudiobooksFilterSort.getSortOrder()
        @State var ascending = AudiobooksFilterSort.getAscending()
        
        var body: some View {
            NavigationStack {
                Group {
                    if audiobooks.isEmpty {
                        if failed {
                            ErrorView()
                        } else {
                            LoadingView()
                        }
                    } else {
                        let sorted = AudiobooksFilterSort.filterSort(audiobooks: audiobooks, filter: filter, order: sortOrder, ascending: ascending)
                        
                        if displayOrder == .grid {
                            ScrollView {
                                AudiobookGrid(audiobooks: sorted)
                                    .padding(.horizontal)
                            }
                        } else if displayOrder == .list {
                            List {
                                AudiobooksList(audiobooks: sorted)
                            }
                            .listStyle(.plain)
                        }
                    }
                }
                .navigationTitle("title.library")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        NavigationLink(destination: AuthorsView()) {
                            Image(systemName: "person.fill")
                        }
                    }
                    
                    ToolbarItem(placement: .topBarTrailing) {
                        AudiobooksFilterSort(display: $displayOrder, filter: $filter, sort: $sortOrder, ascending: $ascending)
                    }
                }
                .modifier(NowPlayingBarSafeAreaModifier())
                .task(fetchAudiobooks)
                .refreshable(action: fetchAudiobooks)
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("tab.library", systemImage: "book.fill")
            }
        }
    }
}

// MARK: Helper

extension AudiobookLibraryView.LibraryView {
    @Sendable
    func fetchAudiobooks() {
        Task.detached {
            if let audiobooks = try? await AudiobookshelfClient.shared.getAudiobooks(libraryId: libraryId) {
                self.audiobooks = audiobooks
            } else {
                failed = true
            }
        }
    }
}
