//
//  AuthorsView.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import SwiftUI
import SPBase

struct AuthorsView: View {
    @Environment(\.libraryId) var libraryId
    
    @State var authors = [Author]()
    @State var failed = false
    
    var body: some View {
        Group {
            if authors.isEmpty {
                if failed {
                    ErrorView()
                } else {
                    LoadingView()
                        .task { await loadAuthors() }
                }
            } else {
                List {
                    AuthorList(authors: authors)
                }
                .navigationTitle("authors.title")
            }
        }
        .refreshable { await loadAuthors() }
    }
}

extension AuthorsView {
    func loadAuthors() async {
        failed = false
        
        if let authors = try? await AudiobookshelfClient.shared.getAuthors(libraryId: libraryId) {
            self.authors = authors
        } else {
            failed = true
        }
    }
}

#Preview {
    AuthorsView()
}
