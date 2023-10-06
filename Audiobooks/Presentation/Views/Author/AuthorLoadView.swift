//
//  AuthorLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI

struct AuthorLoadView: View {
    @Environment(\.libraryId) var libraryId
    
    let authorId: String
    
    @State var failed = false
    @State var author: Author?
    @State var audiobooks: [Audiobook]?
    
    var body: some View {
        if failed {
            AuthorUnavailableView()
        } else if let author = author {
            AuthorView(author: author, audiobooks: audiobooks)
        } else {
            LoadingView()
                .task {
                    if let author = try? await AudiobookshelfClient.shared.getAuthorData(authorId: authorId, libraryId: libraryId) {
                        
                        self.audiobooks = author.1
                        self.author = author.0
                    } else {
                        failed = true
                    }
                }
        }
    }
}

#Preview {
    AuthorLoadView(authorId: Author.fixture.id)
}
