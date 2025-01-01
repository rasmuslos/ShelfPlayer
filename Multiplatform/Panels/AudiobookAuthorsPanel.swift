//
//  AuthorsView.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct AudiobookAuthorsPanel: View {
    @Environment(\.library) private var library
    @Default(.authorsAscending) private var authorsAscending
    
    @State private var failed = false
    @State private var authors = [Author]()
    
    private var sorted: [Author] {
        authors.sorted {
            $0.name.localizedStandardCompare($1.name) == (authorsAscending ? .orderedDescending : .orderedAscending)
        }
    }
    
    var body: some View {
        if authors.isEmpty {
            if failed {
                ErrorView()
                    .refreshable {
                        await loadAuthors()
                    }
            } else {
                LoadingView()
                    .task {
                        await loadAuthors()
                    }
                    .refreshable {
                        await loadAuthors()
                    }
            }
        } else {
            List {
                AuthorList(authors: sorted)
            }
            .listStyle(.plain)
            .navigationTitle("panel.authors")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Toggle("ascending", systemImage: authorsAscending ? "arrowshape.up.circle" : "arrowshape.down.circle", isOn: $authorsAscending)
                        .foregroundStyle(Color.accentColor)
                        .contentTransition(.symbolEffect(.replace))
                        .toggleStyle(.button)
                        .buttonStyle(.plain)
                }
            }
            .refreshable {
                await loadAuthors()
            }
        }
    }
    
    private nonisolated func loadAuthors() async {
        /*
        guard let authors = try? await AudiobookshelfClient.shared.authors(libraryID: library.id) else {
            await MainActor.withAnimation {
                failed = true
            }
            
            return
        }
        
        await MainActor.withAnimation {
            self.authors = authors
        }
         */
    }
}

#Preview {
    AudiobookAuthorsPanel()
}
