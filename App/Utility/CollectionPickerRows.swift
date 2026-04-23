//
//  CollectionPickerRows.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.04.26.
//

import SwiftUI
import ShelfPlayback

/// Lazy-loaded list rows of a library's collections or playlists. Each row
/// shows a leading plus-circle (or check when disabled), the collection's
/// type icon, and its name. Tapping calls `onPick`.
///
/// Designed to live inside a `Section { ... }` in a List — the loading /
/// failure / empty states render inline so the caller doesn't have to
/// coordinate them. Drop it in and provide an `onPick` action.
struct CollectionPickerRows: View {
    let library: Library
    let type: ItemCollection.CollectionType
    let onPick: (ItemIdentifier) -> Void
    var isDisabled: (ItemCollection) -> Bool = { _ in false }

    @State private var lazyLoader: LazyLoadHelper<ItemCollection, Void?>

    init(library: Library,
         type: ItemCollection.CollectionType,
         onPick: @escaping (ItemIdentifier) -> Void,
         isDisabled: @escaping (ItemCollection) -> Bool = { _ in false }) {
        self.library = library
        self.type = type
        self.onPick = onPick
        self.isDisabled = isDisabled
        _lazyLoader = .init(initialValue: .collections(type))
    }

    private var typeIcon: String {
        type == .collection ? "rectangle.stack.fill" : "music.note.list"
    }

    var body: some View {
        Group {
            if lazyLoader.items.isEmpty {
                if lazyLoader.failed {
                    Label("error.generic", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                } else if lazyLoader.working {
                    HStack {
                        ProgressView()
                        Spacer(minLength: 0)
                    }
                } else {
                    Text("home.customization.collectionPicker.empty")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(lazyLoader.items) { collection in
                    let disabled = isDisabled(collection)
                    HStack(spacing: 12) {
                        Image(systemName: disabled ? "checkmark.circle.fill" : "plus.circle.fill")
                            .foregroundStyle(.white, disabled ? Color.gray : .green)
                            .font(.title3)
                        Image(systemName: typeIcon)
                            .foregroundStyle(Color.accentColor)
                            .frame(width: 22)
                        Text(collection.name)
                            .foregroundStyle(disabled ? .secondary : .primary)
                        Spacer(minLength: 0)
                    }
                    .contentShape(.rect)
                    // `onTapGesture` (not `Button`) so taps fire inside a
                    // List that has editMode forced to .active — Button taps
                    // are eaten by the edit-mode collection view.
                    .onTapGesture {
                        guard !disabled else { return }
                        onPick(collection.id)
                    }
                    .onAppear {
                        lazyLoader.performLoadIfRequired(collection)
                    }
                }
            }
        }
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
        }
    }
}
