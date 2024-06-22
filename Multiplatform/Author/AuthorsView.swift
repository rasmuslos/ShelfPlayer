//
//  AuthorsView.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import SwiftUI
import Defaults
import SPBase

internal struct AuthorsView: View {
    @Environment(\.libraryId) private var libraryId
    @Default(.authorsAscending) private var authorsAscending
    
    @State private var failed = false
    @State private var authors = [Author]()
    
    private var sorted: [Author] {
        authors.sorted {
            $0.name.localizedStandardCompare($1.name) == (authorsAscending ? .orderedAscending : .orderedDescending)
        }
    }
    
    var body: some View {
        if authors.isEmpty {
            if failed {
                ErrorView()
                    .refreshable { await loadAuthors() }
            } else {
                LoadingView()
                    .task { await loadAuthors() }
            }
        } else {
            List {
                AuthorList(authors: sorted)
            }
            .listStyle(.plain)
            .navigationTitle("authors.title")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        withAnimation {
                            authorsAscending.toggle()
                        }
                    } label: {
                        Label("ascending", systemImage: "arrow.up.arrow.down.circle")
                            .labelStyle(.iconOnly)
                            .symbolVariant(authorsAscending ? .none : .fill)
                    }
                }
            }
            .refreshable { await loadAuthors() }
        }
    }
    
    func loadAuthors() async {
        guard let authors = try? await AudiobookshelfClient.shared.getAuthors(libraryId: libraryId) else {
            failed = true
            return
        }
        
        self.authors = authors
    }
}

#Preview {
    AuthorsView()
}
