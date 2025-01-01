//
//  AuthorLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct AuthorLoadView: View {
    @Environment(\.library) private var library
    
    private var authorID: String?
    private var authorName: String?
    
    init(authorID: String?) {
        self.authorID = authorID
        authorName = nil
    }
    init (authorName: String) {
        authorID = nil
        self.authorName = authorName
    }
    
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
                .refreshable {
                    await loadAuthor()
                }
        }
    }
    
    private nonisolated func loadAuthor() async {
        do {
            let authorID: String
            
            if let provided = self.authorID {
                authorID = provided
            } else if let authorName {
                // authorID = try await ABSClient[].authorID(name: authorName, libraryID: library.id)
            } else {
                return
            }
            
            // let author = try await AudiobookshelfClient.shared.author(authorId: authorID, libraryID: library.id)
            
            await MainActor.withAnimation {
                self.author = author
            }
        } catch {
            await MainActor.withAnimation {
                failed = true
            }
        }
    }
}
