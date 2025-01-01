//
//  SearchLibraryPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 15.11.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

struct SearchLibraryPicker: ViewModifier {
    @State private var search: String? = nil
    @State private var libraries: [Library]? = nil
    
    func body(content: Content) -> some View {
        content
            .onReceive(Search.shared.searchPublisher) { (library, search) in
                guard library == nil else {
                    self.search = nil
                    return
                }
                
                libraries = []
                self.search = search
            }
            .sheet(item: $search) { search in
                NavigationStack {
                    List {
                        if let libraries {
                            if libraries.isEmpty {
                                Text("search.libraries.empty")
                                    .foregroundStyle(.secondary)
                            } else {
                                Section {
                                    SelectLibraryModifier.LibraryMenu(libraries: libraries) {
                                        Search.shared.emit(library: $0, search: search)
                                    }
                                } footer: {
                                    Text("search.library.select \(search)")
                                }
                            }
                        } else if libraries == nil {
                            ProgressIndicator()
                        }
                    }
                    .navigationTitle("search.library.select")
                    .navigationBarTitleDisplayMode(.inline)
                    .animation(.smooth, value: libraries)
                    .task(fetchLibraries)
                }
            }
    }
    
    @Sendable
    private nonisolated func fetchLibraries() async {
        /*
        let libraries = try? await AudiobookshelfClient.shared.libraries()
        
        await MainActor.run {
            self.libraries = libraries ?? []
        }
         */
    }
}
