//
//  HomeCustomizationView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI
import ShelfPlayback

struct HomeCustomizationView: View {
    let scope: HomeScope
    /// Library type context when the scope is a library scope. Ignored for
    /// the multi-library scope (per-section pickers determine semantics).
    let libraryType: LibraryMediaType?

    @Environment(ConnectionStore.self) private var connectionStore

    @State private var sections: [HomeSection] = []
    @State private var isLoading = true
    /// Cache of libraries keyed by connection. Loaded on appear so the
    /// multi-library library picker can render without needing
    /// `TabRouterViewModel` (which isn't in scope when this view is
    /// presented as a sheet from `ContentView`).
    @State private var connectionLibraries: [ItemIdentifier.ConnectionID: [Library]] = [:]

    private var isMultiLibraryScope: Bool {
        if case .multiLibrary = scope { true } else { false }
    }

    private var availableKindsToAdd: [HomeSectionKind] {
        let all: [HomeSectionKind]
        if isMultiLibraryScope {
            all = PersistenceManager.shared.homeCustomization.availableMultiLibraryKinds()
        } else {
            all = PersistenceManager.shared.homeCustomization.availableKinds(for: libraryType ?? .audiobooks)
        }

        let present = Set(sections.map(\.kind.stableID))
        return all.filter { !present.contains($0.stableID) }
    }

    /// Collection types that can still be pinned. We always allow adding
    /// more — a user may want multiple collection rows.
    private var addableCollectionTypes: [ItemCollection.CollectionType] {
        switch libraryType {
        case .audiobooks: [.collection]
        case .podcasts: [.playlist]
        case nil: [.collection, .playlist]
        }
    }

    var body: some View {
        List {
            if isLoading {
                ProgressView()
            } else {
                Section {
                    ForEach($sections) { $section in
                        HomeCustomizationRow(section: $section, showLibraryPicker: isMultiLibraryScope, connectionLibraries: connectionLibraries)
                    }
                    .onMove { indices, destination in
                        moveSections(from: indices, to: destination)
                    }
                    .onDelete { indices in
                        deleteSections(at: indices)
                    }
                } footer: {
                    Text("home.customization.footer")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !availableKindsToAdd.isEmpty {
                    Section {
                        ForEach(availableKindsToAdd, id: \.stableID) { kind in
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.white, .green)
                                    .font(.title3)
                                Image(systemName: kind.systemImage)
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 22)
                                Text(kind.defaultLocalizedTitle)
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                            }
                            .contentShape(.rect)
                            .onTapGesture {
                                add(kind)
                            }
                        }
                    } header: {
                        Text("home.customization.addSection")
                    }
                }

                collectionPickerSections
            }
        }
        .navigationTitle(isMultiLibraryScope ? "home.customization.multiLibraryTitle" : "home.customization.title")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        reset()
                    } label: {
                        Label("home.customization.reset", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        // Persist whenever the multi-library scope's library picker mutates a
        // row's libraryID through the @Binding. Every other mutation (add /
        // delete / move / reset) calls `persist()` directly, so we only need
        // to react to the library-picker case here.
        .onChange(of: sections.map(\.libraryID)) {
            guard !isLoading else { return }
            persist()
        }
        .task {
            await load()
        }
        .task(id: isMultiLibraryScope) {
            guard isMultiLibraryScope else { return }
            await loadConnectionLibraries()
        }
    }

    // MARK: - Collection picker sections
    //
    // Enumerates available collections (audiobook libraries) and playlists
    // (podcast libraries) inline as tappable rows. Previously the "Add
    // Collection" / "Add Playlist" rows presented a sheet — but presenting
    // any modal over this edit-mode List reliably trips the
    // UICollectionViewFeedbackLoopDebugger on iOS 26. Inline enumeration
    // avoids the modal transition entirely.
    @ViewBuilder
    private var collectionPickerSections: some View {
        if let libraryID = scope.implicitLibraryID {
            // Library scope — exactly one library and one collection type.
            let library = syntheticLibrary(from: libraryID)
            ForEach(addableCollectionTypes, id: \.self) { type in
                Section {
                    CollectionPickerRows(
                        library: library,
                        type: type,
                        onPick: { itemID in addCollection(type: type, itemID: itemID) },
                        isDisabled: { isCollectionPinned($0.id, type: type) }
                    )
                } header: {
                    Text(type == .collection
                         ? "home.customization.addCollection"
                         : "home.customization.addPlaylist")
                }
            }
        } else {
            // Multi-library scope — enumerate every library; audiobook
            // libraries contribute collections, podcast libraries playlists.
            LibraryEnumerator { name, content in
                Section {
                    content()
                } header: {
                    Text(name)
                }
            } label: { library in
                let type: ItemCollection.CollectionType = library.id.type == .audiobooks ? .collection : .playlist
                DisclosureGroup(library.name) {
                    CollectionPickerRows(
                        library: library,
                        type: type,
                        onPick: { itemID in addCollection(type: type, itemID: itemID) },
                        isDisabled: { isCollectionPinned($0.id, type: type) }
                    )
                }
            }
        }
    }

    private func isCollectionPinned(_ itemID: ItemIdentifier, type: ItemCollection.CollectionType) -> Bool {
        let stableID: String = switch type {
        case .collection: HomeSectionKind.collection(itemID: itemID.description).stableID
        case .playlist: HomeSectionKind.playlist(itemID: itemID.description).stableID
        }
        return sections.contains { $0.kind.stableID == stableID }
    }

    private func syntheticLibrary(from identifier: LibraryIdentifier) -> Library {
        Library(id: identifier.libraryID,
                connectionID: identifier.connectionID,
                name: "",
                type: identifier.type,
                index: 0)
    }

    private func add(_ kind: HomeSectionKind) {
        sections.append(.init(kind: kind, libraryID: scope.implicitLibraryID))
        persist()
    }

    private func addCollection(type: ItemCollection.CollectionType, itemID: ItemIdentifier) {
        let kind: HomeSectionKind = switch type {
        case .collection: .collection(itemID: itemID.description)
        case .playlist: .playlist(itemID: itemID.description)
        }
        // Don't add if the same collection is already pinned.
        guard !sections.contains(where: { $0.kind.stableID == kind.stableID }) else { return }

        let override: LibraryIdentifier? = isMultiLibraryScope
            ? LibraryIdentifier.convertItemIdentifierToLibraryIdentifier(itemID)
            : scope.implicitLibraryID
        sections.append(.init(kind: kind, libraryID: override))
        persist()
    }

    private func moveSections(from source: IndexSet, to destination: Int) {
        sections.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    private func deleteSections(at indices: IndexSet) {
        sections.remove(atOffsets: indices)
        persist()
    }

    private func load() async {
        let loaded = await PersistenceManager.shared.homeCustomization.sections(for: scope, libraryType: libraryType)
        await MainActor.run {
            sections = loaded
            isLoading = false
        }
    }

    private func loadConnectionLibraries() async {
        await withTaskGroup(of: (ItemIdentifier.ConnectionID, [Library]?).self) { group in
            for connection in connectionStore.connections {
                group.addTask {
                    let libraries = try? await ABSClient[connection.id].libraries()
                    return (connection.id, libraries)
                }
            }

            for await (connectionID, libraries) in group {
                if let libraries {
                    connectionLibraries[connectionID] = libraries
                }
            }
        }
    }

    private func persist() {
        let snapshot = sections
        Task {
            try? await PersistenceManager.shared.homeCustomization.setSections(snapshot, for: scope)
        }
    }

    private func reset() {
        Task {
            try? await PersistenceManager.shared.homeCustomization.setSections(nil, for: scope)
            await load()
        }
    }
}

// MARK: - Row

private struct HomeCustomizationRow: View {
    @Binding var section: HomeSection
    let showLibraryPicker: Bool
    let connectionLibraries: [ItemIdentifier.ConnectionID: [Library]]

    private var pinnedCollectionID: ItemIdentifier? {
        let raw: String
        switch section.kind {
        case .collection(let id), .playlist(let id):
            raw = id
        default:
            return nil
        }
        guard ItemIdentifier.isValid(raw) else { return nil }
        return ItemIdentifier(string: raw)
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.kind.systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)

            if let itemID = pinnedCollectionID {
                ResolvedCollectionTitle(itemID: itemID, fallback: section.kind.defaultLocalizedTitle)
            } else {
                Text(section.kind.defaultLocalizedTitle)
                    .foregroundStyle(.primary)
            }

            Spacer(minLength: 0)

            if showLibraryPicker {
                HomeSectionLibraryMenu(libraryID: $section.libraryID, connectionLibraries: connectionLibraries)
            }
        }
        .contentShape(.rect)
    }
}

/// Resolves a pinned collection / playlist and displays its actual name; falls
/// back to the generic "Collection" / "Playlist" label while loading (or if
/// the collection can't be resolved at all).
private struct ResolvedCollectionTitle: View {
    let itemID: ItemIdentifier
    let fallback: String

    @State private var name: String?

    var body: some View {
        Text(name ?? fallback)
            .foregroundStyle(.primary)
            .task(id: itemID) {
                if let collection = try? await ResolveCache.shared.resolve(itemID) as? ItemCollection {
                    name = collection.name
                }
            }
    }
}

// MARK: - Library picker (multi-library scope)

/// Trailing menu on a customization row that lets the user pin the row to a
/// specific library (or "Any Library" for cross-library aggregation). Mirrors
/// `LibraryPicker`'s connection-grouped structure.
private struct HomeSectionLibraryMenu: View {
    @Binding var libraryID: LibraryIdentifier?
    let connectionLibraries: [ItemIdentifier.ConnectionID: [Library]]

    @Environment(ConnectionStore.self) private var connectionStore

    private var hiddenLibraries: Set<LibraryIdentifier> { AppSettings.shared.hiddenLibraries }

    private var connectionIDs: [ItemIdentifier.ConnectionID] {
        Array(connectionLibraries.keys.sorted())
    }

    private var currentLabel: String {
        guard let libraryID else {
            return String(localized: "home.customization.libraryPicker.any")
        }
        for libraries in connectionLibraries.values {
            if let match = libraries.first(where: { $0.id == libraryID }) {
                return match.name
            }
        }
        return libraryID.libraryID
    }

    var body: some View {
        Menu {
            Button {
                libraryID = nil
            } label: {
                Label("home.customization.libraryPicker.any", systemImage: libraryID == nil ? "checkmark" : "square.grid.2x2")
            }

            ForEach(connectionIDs, id: \.hashValue) { connectionID in
                if let connection = connectionStore.connections.first(where: { $0.id == connectionID }),
                   let libraries = connectionLibraries[connectionID] {
                    let visible = libraries.filter { !hiddenLibraries.contains($0.id) }

                    if !visible.isEmpty {
                        Section(connection.name) {
                            ForEach(visible) { library in
                                Button {
                                    libraryID = library.id
                                } label: {
                                    Label(library.name, systemImage: libraryID == library.id ? "checkmark" : library.icon)
                                }
                            }
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(currentLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 8)
            .background(.quaternary.opacity(0.5), in: .capsule)
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        HomeCustomizationView(scope: .library(Library.fixture.id), libraryType: .audiobooks)
    }
    .previewEnvironment()
}
#endif
