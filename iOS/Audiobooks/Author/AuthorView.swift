//
//  AuthorView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPBase

struct AuthorView: View {
    @Environment(\.libraryId) var libraryId
    
    let author: Author
    @State var audiobooks: [Audiobook]?
    @State var displayOrder = AudiobooksFilterSort.getDisplayType()
    @State var filter = AudiobooksFilterSort.getFilter()
    @State var sortOrder = AudiobooksFilterSort.getSortOrder()
    @State var ascending = AudiobooksFilterSort.getAscending()
    
    var body: some View {
        Group {
            if let audiobooks = audiobooks {
                let sorted = AudiobooksFilterSort.filterSort(audiobooks: audiobooks, filter: filter, order: sortOrder, ascending: ascending)
                
                if displayOrder == .grid {
                    ScrollView {
                        Header(author: author)
                        AudiobookGrid(audiobooks: sorted)
                            .padding()
                    }
                } else if displayOrder == .list {
                    List {
                        HStack {
                            Spacer()
                            
                            Header(author: author)
                            
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                        
                        AudiobooksList(audiobooks: sorted)
                    }
                    .listStyle(.plain)
                }
            } else {
                VStack {
                    Header(author: author)
                    
                    Spacer()
                    LoadingView()
                    Spacer()
                }
            }
        }
        .navigationTitle(author.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                AudiobooksFilterSort(display: $displayOrder, filter: $filter, sort: $sortOrder, ascending: $ascending)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(verbatim: "")
            }
        }
        .modifier(NowPlayingBarSafeAreaModifier())
        .onAppear {
            if audiobooks == nil {
                fetchAudiobooks()
            }
        }
        .refreshable(action: fetchAudiobooks)
    }
}

// MARK: Helper

extension AuthorView {
    @Sendable
    func fetchAudiobooks() {
        Task.detached {
            audiobooks = try? await AudiobookshelfClient.shared.getAuthorData(authorId: author.id, libraryId: libraryId).1
        }
    }
}

#Preview {
    NavigationStack {
        AuthorView(author: Author.fixture)
    }
}
