//
//  AudiobookLibraryView+Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

extension AudiobookLibraryView {
    struct LibraryView: View {
        @Environment(\.libraryId) var libraryId
        
        @State var failed = false
        @State var audiobooks = [Audiobook]()
        @State var displayOrder = AudiobooksSort.getDisplayType()
        @State var sortOrder = AudiobooksSort.getSortOrder()
        
        var body: some View {
            NavigationStack {
                Group {
                    if failed {
                        ErrorView()
                    } else if audiobooks.isEmpty {
                        LoadingView()
                    } else {
                        let sorted = AudiobooksSort.sort(audiobooks: audiobooks, order: sortOrder)
                        
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
                .navigationTitle("Library")
                .navigationBarTitleDisplayMode(.large)
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        AudiobooksSort(display: $displayOrder, sort: $sortOrder)
                    }
                }
                .modifier(NowPlayingBarSafeAreaModifier())
                .task(fetchAudiobooks)
                .refreshable(action: fetchAudiobooks)
            }
            .modifier(NowPlayingBarModifier())
            .tabItem {
                Label("Library", systemImage: "book.fill")
            }
        }
    }
}

// MARK: Helper

extension AudiobookLibraryView.LibraryView {
    @Sendable
    func fetchAudiobooks() {
        Task.detached {
            if let audiobooks = try? await AudiobookshelfClient.shared.getAllAudiobooks(libraryId: libraryId) {
                self.audiobooks = audiobooks
            } else {
                failed = true
            }
        }
    }
}
