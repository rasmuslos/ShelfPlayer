//
//  CollectionsPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.07.25.
//

import SwiftUI
import ShelfPlayback

struct CollectionsPanel: View {
    @Environment(\.library) private var library

    let type: ItemCollection.CollectionType

    @State private var lazyLoader: LazyLoadHelper<ItemCollection, Void?>

    init(type: ItemCollection.CollectionType) {
        self.type = type
        _lazyLoader = .init(initialValue: .collections(type))
    }

    var body: some View {
        Group {
            if lazyLoader.items.isEmpty {
                Group {
                    if lazyLoader.failed {
                        ErrorView()
                    } else if lazyLoader.working {
                        LoadingView()
                    } else {
                        EmptyCollectionView()
                    }
                }
                .refreshable {
                    lazyLoader.refresh()
                }
            } else {
                List {
                    ForEach(lazyLoader.items) { collection in
                        NavigationLink(value: NavigationDestination.item(collection)) {
                            ItemCompactRow(item: collection, context: .collectionLarge)
                        }
                        .onAppear {
                            lazyLoader.performLoadIfRequired(collection)
                        }
                    }
                }
                .listStyle(.plain)
                .refreshable {
                    lazyLoader.refresh()
                }
            }
        }
        .navigationTitle(type.label)
        .largeTitleDisplayMode()
        .modifier(PlaybackSafeAreaPaddingModifier())
        .onReceive(CollectionEventSource.shared.changed) { _ in
            lazyLoader.refresh()
        }
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
        }
    }
}

extension ItemCollection.CollectionType {
    var label: LocalizedStringKey {
        switch self {
        case .collection:
            "panel.collections"
        case .playlist:
            "panel.playlists"
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CollectionsPanel(type: .collection)
            .previewEnvironment()
    }
}
#endif
