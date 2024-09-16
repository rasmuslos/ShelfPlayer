//
//  AuthorLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct AuthorLoadView: View {
    @Environment(\.libraryId) private var libraryId
    
    let authorId: String
    
    @State private var failed = false
    @State private var author: (Author, [Audiobook], [Series])?
    
    var body: some View {
        if let author = author {
            AuthorView(author.0, series: author.2, audiobooks: author.1)
        } else if failed {
            AuthorUnavailableView()
                .refreshable {
                    await loadAuthor()
                }
        } else {
            LoadingView()
                .task {
                    await loadAuthor()
                }
        }
    }
    
    private nonisolated func loadAuthor() async {
        guard let author = try? await AudiobookshelfClient.shared.author(authorId: authorId, libraryId: libraryId) else {
            await MainActor.run {
                failed = true
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.author = author
        }
    }
}
