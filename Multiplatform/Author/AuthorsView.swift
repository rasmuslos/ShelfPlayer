//
//  AuthorsView.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import SwiftUI
import Defaults
import SPBase

struct AuthorsView: View {
    @Environment(\.libraryId) private var libraryId
    @Default(.authorsAscending) private var authorsAscending
    
    @State private var authors = [Author]()
    @State private var failed = false
    
    private var authorsSorted: [Author] {
        authors.sorted {
            $0.name.localizedStandardCompare($1.name) == (authorsAscending ? .orderedAscending : .orderedDescending)
        }
    }
    
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
                    AuthorList(authors: authorsSorted)
                }
                .navigationTitle("authors.title")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            withAnimation {
                                authorsAscending.toggle()
                            }
                        } label: {
                            Image(systemName: "arrow.down.circle")
                                .symbolVariant(authorsAscending ? .fill : .none)
                        }
                    }
                }
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
