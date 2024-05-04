//
//  AuthorLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import SPBase

struct AuthorLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let authorId: String
    
    @State private var failed = false
    @State private var author: Author?
    @State private var audiobooks: [Audiobook]?
    
    var body: some View {
        if failed {
            AuthorUnavailableView()
        } else if let author = author {
            AuthorView(author: author, audiobooks: audiobooks ?? [])
        } else {
            LoadingView()
                .task { await fetchAuthor() }
                .refreshable { await fetchAuthor() }
        }
    }
}

extension AuthorLoadView {
    private func fetchAuthor() async {
        failed = false
        
        if let author = try? await AudiobookshelfClient.shared.getAuthorData(authorId: authorId, libraryId: libraryId) {
            self.audiobooks = author.1
            self.author = author.0
        } else {
            failed = true
        }
    }
}
