//
//  AudiobookBookmarksPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 20.05.25.
//

import SwiftUI
import OSLog
import ShelfPlayback

private let audiobookBookmarksPanelLogger = Logger(subsystem: "io.rfk.shelfPlayer", category: "AudiobookBookmarksPanel")

struct AudiobookBookmarksPanel: View {
    @Environment(\.library) private var library

    @State private var items = [Audiobook: Int]()

    @State private var ascending = AppSettings.shared.bookmarksAscending
    @State private var sortOrder = AppSettings.shared.bookmarksSortOrder

    private var sortedItems: [(key: Audiobook, value: Int)] {
        let entries = Array(items)

        return entries.sorted { lhs, rhs in
            let result: Bool

            switch sortOrder {
            case .name:
                result = lhs.key.sortName.localizedStandardCompare(rhs.key.sortName) == .orderedAscending
            case .bookmarkCount:
                result = lhs.value < rhs.value
            }

            return ascending ? result : !result
        }
    }

    var body: some View {
        Group {
            if items.isEmpty {
                EmptyCollectionView()
            } else {
                List {
                    ForEach(sortedItems, id: \.key) { (item, amount) in
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
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu("item.options", systemImage: "arrow.up.arrow.down") {
                    Section("item.sort") {
                        ItemSortOrderPicker(sortOrder: $sortOrder, ascending: $ascending)
                    }
                }
                .menuActionDismissBehavior(.disabled)
            }
        }
        .onChange(of: sortOrder) {
            AppSettings.shared.bookmarksSortOrder = sortOrder
        }
        .onChange(of: ascending) {
            AppSettings.shared.bookmarksAscending = ascending
        }
        .task {
            load()
        }
        .refreshable {
            load()
        }
    }

    private func load() {
        Task {
            guard let library else {
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
                let item: Audiobook?
                do {
                    item = try await ResolveCache.shared.resolve(primaryID: primaryID, groupingID: nil, connectionID: library.id.connectionID) as? Audiobook
                } catch {
                    audiobookBookmarksPanelLogger.warning("Failed to resolve bookmark item \(primaryID, privacy: .public): \(error, privacy: .public)")
                    continue
                }

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
