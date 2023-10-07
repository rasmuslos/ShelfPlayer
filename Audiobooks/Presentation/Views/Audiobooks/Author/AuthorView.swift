//
//  AuthorView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI

struct AuthorView: View {
    @Environment(\.libraryId) var libraryId
    
    let author: Author
    @State var audiobooks: [Audiobook]?
    @State var displayOrder = AudiobooksSort.getDisplayType()
    @State var sortOrder = AudiobooksSort.getSortOrder()
    
    var body: some View {
        Group {
            if let audiobooks = audiobooks {
                let sorted = AudiobooksSort.sort(audiobooks: audiobooks, order: sortOrder)
                
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
                AudiobooksSort(display: $displayOrder, sort: $sortOrder)
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("")
            }
        }
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
            audiobooks = try? await AudiobookshelfClient.shared.getAudiobooksByAuthor(authorId: author.id, libraryId: libraryId)
        }
    }
}

#Preview {
    NavigationStack {
        AuthorView(author: Author.fixture)
    }
}
