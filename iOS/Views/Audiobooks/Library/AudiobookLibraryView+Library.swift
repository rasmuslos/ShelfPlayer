//
//  AudiobookLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import ShelfPlayerKit

extension AudiobookLibraryView {
    struct LibraryView: View {
        @Environment(\.libraryId) var libraryId
        
        @State var failed = false
        @State var audiobooks = [Audiobook]()
        @State var displayOrder = AudiobooksSort.getDisplayType()
        @State var sortOrder = AudiobooksSort.getSortOrder()
        @State var ascending = AudiobooksSort.getAscending()
        
        var body: some View {
            NavigationStack {
                Group {
                    if failed {
                        ErrorView()
                    } else if audiobooks.isEmpty {
                        LoadingView()
                    } else {
                        let sorted = AudiobooksSort.sort(audiobooks: audiobooks, order: sortOrder, ascending: ascending)
                        
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
                        AudiobooksSort(display: $displayOrder, sort: $sortOrder, ascending: $ascending)
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
