//
//  AudiobookBookmarksPanel.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 20.05.25.
//

import SwiftUI
import ShelfPlayerKit

struct AudiobookBookmarksPanel: View {
    @Environment(\.library) private var library
    
    @State private var items = [Audiobook]()
    
    var body: some View {
        Group {
            if items.isEmpty {
                EmptyCollectionView()
            } else {
                List {
                    ForEach(items) { item in
                        NavigationLink(destination: AudiobookBookmarkView(audiobook: item)) {
                            ItemCompactRow(item: item) {}
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
        .navigationTitle("panel.bookmarks")
        .task {
            load()
        }
        .refreshable {
            load()
        }
    }
    
    private nonisolated func load() {
        Task {
            guard let library = await library else {
                #if DEBUG
                await MainActor.withAnimation {
                    items = [
                        Audiobook.fixture,
                    ]
                }
                #endif
                
                return
            }
            
            let possiblePrimaryIDs = try await PersistenceManager.shared.bookmark[library].sorted(by: <)
            
            for primaryID in possiblePrimaryIDs {
                let item = try? await ABSClient[library.connectionID].playableItem(primaryID: primaryID, groupingID: nil).0 as? Audiobook
                
                guard let item, item.id.libraryID == library.id, await !items.contains(where: { $0.id == item.id }) else {
                    continue
                }
                
                await MainActor.withAnimation {
                    items.append(item)
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
