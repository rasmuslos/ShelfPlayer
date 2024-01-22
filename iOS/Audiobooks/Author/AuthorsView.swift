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
    
    @State var authors: [Author]?
    @State var failed = false
    
    var body: some View {
        if let authors, !authors.isEmpty {
            List {
                ForEach(authors) { author in
                    NavigationLink(destination: AuthorView(author: author)) {
                        AuthorListRow(author: author)
                    }
                }
            }
            .navigationTitle("authors.title")
        } else if failed {
            ErrorView()
        } else {
            LoadingView()
                .onAppear(perform: loadAuthors)
        }
    }
}

extension AuthorsView {
    @Sendable
    func loadAuthors() {
        failed = false
        
        Task {
            do {
                authors = try await AudiobookshelfClient.shared.getAuthors(libraryId: libraryId)
            } catch {
                failed = true
            }
        }
    }
}

#Preview {
    AuthorsView()
}
