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
                        NavigationLink(destination: AudiobookView(item)) {
                            HStack(spacing: 8) {
                                ItemCompactRow(item: item, context: .bookmark)
                                Text(amount, format: .number)
                                    .foregroundStyle(.secondary)
                            }
                            .contentShape(.rect)
                        }
                        .modifier(ItemStatusModifier(item: item, hoverEffect: nil))
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
                        Audiobook.fixture: 3,
                    ]
                }
                #endif
                
                return
            }
            
            let possiblePrimaryIDs = try await PersistenceManager.shared.bookmark[library].sorted(by: <)
            
            for (primaryID, amount) in possiblePrimaryIDs {
                let item = try? await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: nil, connectionID: library.connectionID) as? Audiobook
                
                guard let item, item.id.libraryID == library.id else {
                    continue
                }
                
                await MainActor.withAnimation {
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
