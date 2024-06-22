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
    @Environment(\.libraryId) private var libraryId
    
    @Default(.audiobooksFilter) private var audiobooksFilter
    @Default(.audiobooksDisplay) private var audiobookDisplay
    
    @Default(.audiobooksSortOrder) private var audiobooksSortOrder
    @Default(.audiobooksAscending) private var audiobooksAscending
    
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
                            
                            HStack(spacing: 0) {
                                RowTitle(title: String(localized: "books"), fontDesign: .serif)
                                Spacer()
                            }
                            .padding(.top, 16)
                            .padding(.horizontal, 20)
                            
                            AudiobookVGrid(audiobooks: visibleAudiobooks)
                                .padding(20)
                        }
                    case .list:
                        List {
                            Header(author: author)
                                .listRowSeparator(.hidden)
                                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                            
                            RowTitle(title: String(localized: "books"), fontDesign: .serif)
                                .listRowInsets(.init(top: 16, leading: 20, bottom: 0, trailing: 20))
                            
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
        .modifier(NowPlaying.SafeAreaModifier())
        .task {
            await loadAudiobooks()
        }
        .refreshable {
            await loadAudiobooks()
        }
        .userActivity("io.rfk.shelfplayer.author") {
            $0.title = author.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = author.id
            $0.targetContentIdentifier = "author:\(author.id)"
            $0.userInfo = [
                "authorId": author.id,
            ]
            $0.webpageURL = AudiobookshelfClient.shared.serverUrl.appending(path: "author").appending(path: author.id)
        }
    }
    
    func loadAudiobooks() async {
        guard let audiobooks = try? await AudiobookshelfClient.shared.getAuthorData(authorId: author.id, libraryId: libraryId).1 else {
            return
        }
        
        self.audiobooks = audiobooks
    }
}

#Preview {
    NavigationStack {
        AuthorView(author: Author.fixture)
    }
}
