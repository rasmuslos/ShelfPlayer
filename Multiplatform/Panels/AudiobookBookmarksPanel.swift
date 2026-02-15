//
//  AudiobookBookmarksPanel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.05.25.
//

import SwiftUI
import ShelfPlayback

struct AudiobookBookmarksPanel: View {
    @Environment(\.library) private var library
    
    @State private var items = [Audiobook: Int]()
    
    var body: some View {
        Group {
            if items.isEmpty {
                EmptyCollectionView()
            } else {
                List {
                    ForEach(Array(items), id: \.key) { (item, amount) in
                        AudiobookList.Row(audiobook: item) {
                            Text(amount, format: .number)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                    
                    PanelItemCountLabel(total: items.count, type: .audiobook)
                    
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("panel.bookmarks")
        .largeTitleDisplayMode()
        .task {
            load()
        }
        .refreshable {
            load()
        }
    }
    
    private func load() {
        Task {
            guard let library = library else {
                #if DEBUG
                withAnimation {
                    items = [
                        Audiobook.fixture: 3,
                    ]
                }
                #endif
                
                return
            }
            
            let possiblePrimaryIDs = try await PersistenceManager.shared.bookmark[library.id].sorted(by: <)
            
            for (primaryID, amount) in possiblePrimaryIDs {
                let item = try? await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: nil, connectionID: library.id.connectionID) as? Audiobook
                
                guard let item, item.id.libraryID == library.id.libraryID else {
                    continue
                }
                
                withAnimation {
                    items[item] = amount
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookBookmarksPanel()
    }
    .previewEnvironment()
}
#endif

