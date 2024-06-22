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
    @State private var audiobooks = [Audiobook]()
    
    var body: some View {
        if let author = author {
            AuthorView(author: author, audiobooks: audiobooks)
        } else if failed {
            AuthorUnavailableView()
                .refreshable { await loadAuthor() }
        } else {
            LoadingView()
                .task { await loadAuthor() }
        }
    }
    
    private func loadAuthor() async {
        guard let data = try? await AudiobookshelfClient.shared.getAuthorData(authorId: authorId, libraryId: libraryId) else {
            return
        }
        
        audiobooks = data.1
        author = data.0
    }
}
