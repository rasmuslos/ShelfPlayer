//
//  AudiobookLibraryView+Search.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

extension AudiobookLibraryView {
    struct SearchView: View {
        @State var entities = [OfflineProgress]()
        @State var query = ""
        
        var body: some View {
            NavigationStack {
                List {
                    ForEach(entities.filter { query == "" || $0.id.contains(query) }) {
                        Text("\($0.id) (\($0.additionalId ?? "-")) | \($0.currentTime)")
                    }
                }
                .searchable(text: $query)
                .task {
                    entities = try! OfflineManager.shared.getAllProgressEntities()
                }
            }
            .tabItem {
                Label("Search", systemImage: "magnifyingglass")
            }
        }
    }
}
