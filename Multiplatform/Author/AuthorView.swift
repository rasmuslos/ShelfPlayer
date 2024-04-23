//
//  AuthorView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import Defaults
import SPBase

struct AuthorView: View {
    @Environment(\.libraryId) var libraryId
    
    @Default(.audiobooksDisplay) var audiobookDisplay
    @Default(.audiobooksFilter) var audiobooksFilter
    
    @Default(.audiobooksSortOrder) var audiobooksSortOrder
    @Default(.audiobooksAscending) var audiobooksAscending
    
    let author: Author
    @State var audiobooks = [Audiobook]()
    
    private var visibleAudiobooks: [Audiobook] {
        AudiobookSortFilter.filterSort(audiobooks: audiobooks, filter: audiobooksFilter, order: audiobooksSortOrder, ascending: audiobooksAscending)
    }
    
    var body: some View {
        Group {
            if audiobooks.isEmpty {
                VStack {
                    Header(author: author)
                    
                    Spacer()
                    LoadingView()
                    Spacer()
                }
            } else {
                switch audiobookDisplay {
                    case .grid:
                        ScrollView {
                            Header(author: author)
                            
                            HStack {
                                RowTitle(title: String(localized: "books"), fontDesign: .serif)
                                Spacer()
                            }
                            .padding(.horizontal, 20)
                            
                            AudiobookVGrid(audiobooks: visibleAudiobooks)
                                .padding(20)
                        }
                    case .list:
                        List {
                            HStack {
                                Spacer()
                                
                                Header(author: author)
                                
                                Spacer()
                            }
                            .listRowSeparator(.hidden)
                            .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                            
                            RowTitle(title: String(localized: "books"), fontDesign: .serif)
                                .listRowInsets(.init(top: 0, leading: 20, bottom: 0, trailing: 0))
                            AudiobookList(audiobooks: visibleAudiobooks)
                        }
                        .listStyle(.plain)
                }
            }
        }
        .navigationTitle(author.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AudiobookSortFilter(display: $audiobookDisplay, filter: $audiobooksFilter, sort: $audiobooksSortOrder, ascending: $audiobooksAscending)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(verbatim: "")
            }
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .task {
            if audiobooks.isEmpty {
                await fetchAudiobooks()
            }
        }
        .refreshable { await fetchAudiobooks() }
    }
}

// MARK: Helper

extension AuthorView {
    func fetchAudiobooks() async {
        if let audiobooks = try? await AudiobookshelfClient.shared.getAuthorData(authorId: author.id, libraryId: libraryId).1 {
            self.audiobooks = audiobooks
        }
    }
}

#Preview {
    NavigationStack {
        AuthorView(author: Author.fixture)
    }
}
