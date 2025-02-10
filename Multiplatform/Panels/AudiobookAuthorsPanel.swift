//
//  AuthorsView.swift
//  iOS
//
//  Created by Rasmus Krämer on 07.01.24.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct AudiobookAuthorsPanel: View {
    @Environment(\.library) private var library
    
    @Default(.authorsAscending) private var authorsAscending
    @Default(.authorsSortOrder) private var authorsSortOrder
    
    @State private var lazyLoader = LazyLoadHelper<Author, Void>.authors
    
    var body: some View {
        Group {
            if lazyLoader.items.isEmpty {
                if lazyLoader.failed {
                    ErrorView()
                        .refreshable {
                            lazyLoader.refresh()
                        }
                } else {
                    LoadingView()
                        .onAppear {
                            lazyLoader.initialLoad()
                        }
                        .refreshable {
                            lazyLoader.refresh()
                        }
                }
            } else {
                List {
                    AuthorList(authors: lazyLoader.items) {
                        lazyLoader.performLoadIfRequired($0)
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle("panel.authors")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("options", systemImage: "arrow.up.arrow.down.circle") {
                    ItemSortOrderPicker(sortOrder: $authorsSortOrder, ascending: $authorsAscending)
                }
            }
        }
        // .modifier(NowPlaying.SafeAreaModifier())
        .onAppear {
            lazyLoader.library = library
        }
        .onChange(of: authorsSortOrder) {
            lazyLoader.sortOrder = authorsSortOrder
        }
        .onChange(of: authorsAscending) {
            lazyLoader.ascending = authorsAscending
        }
    }
}

#Preview {
    AudiobookAuthorsPanel()
}
