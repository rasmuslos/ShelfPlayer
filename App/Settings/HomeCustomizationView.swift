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
    /// Library type context when the scope is a library scope. For pinned
    /// scope this should be .audiobooks by convention (ignored; per-section
    /// library pickers determine semantics).
    let libraryType: LibraryMediaType?

    @State private var sections: [HomeSection] = []
    @State private var isLoading = true
    @State private var collectionPickerType: ItemCollection.CollectionType?

    private var isPinnedScope: Bool {
        if case .pinned = scope { true } else { false }
    }

    private var availableKindsToAdd: [HomeSectionKind] {
        let all: [HomeSectionKind]
        if isPinnedScope {
            all = [.listenNow, .upNext, .downloadedAudiobooks, .downloadedEpisodes, .bookmarks]
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
                        HomeCustomizationRow(section: $section, showLibraryPicker: isPinnedScope)
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

                if !availableKindsToAdd.isEmpty || !addableCollectionTypes.isEmpty {
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

                        ForEach(addableCollectionTypes, id: \.self) { type in
                            HStack(spacing: 12) {
                                Image(systemName: "plus.circle.fill")
                                    .foregroundStyle(.white, .green)
                                    .font(.title3)
                                Image(systemName: type == .collection ? "rectangle.stack.fill" : "music.note.list")
                                    .foregroundStyle(Color.accentColor)
                                    .frame(width: 22)
                                Text(type == .collection
                                     ? String(localized: "home.customization.addCollection")
                                     : String(localized: "home.customization.addPlaylist"))
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 0)
                            }
                            .contentShape(.rect)
                            .onTapGesture {
                                collectionPickerType = type
                            }
                        }
                    } header: {
                        Text("home.customization.addSection")
                    }
                }
            }
        }
        .navigationTitle(isPinnedScope ? "home.customization.pinnedTitle" : "home.customization.title")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .animation(.smooth, value: sections)
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
        .sheet(item: $collectionPickerType) { type in
            NavigationStack {
                CollectionSectionPicker(type: type, libraryOverride: scope.implicitLibraryID) { itemID in
                    // Dismiss the sheet first. Mutating `sections` while the
                    // sheet is still on-screen triggers a simultaneous List
                    // row-insertion animation, which reliably crashes
                    // UICollectionView ("recursive layout loop").
                    collectionPickerType = nil
                    Task { @MainActor in
                        try? await Task.sleep(for: .milliseconds(350))
                        addCollection(type: type, itemID: itemID)
                    }
                }
            }
        }
        .onChange(of: sections) {
            guard !isLoading else { return }
            persist()
        }
        .task {
            await load()
        }
    }

    private func add(_ kind: HomeSectionKind) {
        sections.append(.init(kind: kind, libraryID: scope.implicitLibraryID))
    }

    private func addCollection(type: ItemCollection.CollectionType, itemID: ItemIdentifier) {
        let kind: HomeSectionKind = switch type {
        case .collection: .collection(itemID: itemID.description)
        case .playlist: .playlist(itemID: itemID.description)
        }
        // Don't add if the same collection is already pinned.
        guard !sections.contains(where: { $0.kind.stableID == kind.stableID }) else { return }

        let override: LibraryIdentifier? = isPinnedScope
            ? LibraryIdentifier.convertItemIdentifierToLibraryIdentifier(itemID)
            : scope.implicitLibraryID
        sections.append(.init(kind: kind, libraryID: override))
    }

    private func moveSections(from source: IndexSet, to destination: Int) {
        sections.move(fromOffsets: source, toOffset: destination)
    }

    private func deleteSections(at indices: IndexSet) {
        sections.remove(atOffsets: indices)
    }

    private func load() async {
        let loaded = await PersistenceManager.shared.homeCustomization.sections(for: scope, libraryType: libraryType)
        await MainActor.run {
            sections = loaded
            isLoading = false
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

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: section.kind.systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                Text(section.kind.defaultLocalizedTitle)
                    .foregroundStyle(.primary)

                if showLibraryPicker {
                    HomeSectionLibraryPickerLabel(libraryID: $section.libraryID)
                }
            }

            Spacer(minLength: 0)
        }
        .contentShape(.rect)
    }
}

// MARK: - Library picker (pinned scope)

private struct HomeSectionLibraryPickerLabel: View {
    @Binding var libraryID: LibraryIdentifier?

    var body: some View {
        NavigationLink {
            HomeSectionLibraryPicker(libraryID: $libraryID)
        } label: {
            Text(libraryID == nil
                 ? String(localized: "home.customization.libraryPicker.any")
                 : libraryID!.libraryID)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .buttonStyle(.plain)
    }
}

private struct HomeSectionLibraryPicker: View {
    @Binding var libraryID: LibraryIdentifier?
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        List {
            Section {
                Button {
                    libraryID = nil
                    dismiss()
                } label: {
                    HStack {
                        Text("home.customization.libraryPicker.any")
                            .foregroundStyle(.primary)
                        Spacer()
                        if libraryID == nil {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }

            LibraryEnumerator { name, content in
                Section(name) { content() }
            } label: { library in
                Button {
                    libraryID = library.id
                    dismiss()
                } label: {
                    HStack {
                        Text(library.name)
                            .foregroundStyle(.primary)
                        Spacer()
                        if libraryID == library.id {
                            Image(systemName: "checkmark")
                                .foregroundStyle(Color.accentColor)
                        }
                    }
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle("home.customization.libraryPicker.title")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Collection picker

/// Lets the user pick one of their collections or playlists to pin as a home
/// section. Enumerates libraries via `LibraryEnumerator` and lazy-loads the
/// items of the chosen library when tapped.
private struct CollectionSectionPicker: View {
    let type: ItemCollection.CollectionType
    /// When set (library-scope customization), the picker skips the library
    /// enumerator and shows only this library's collections/playlists. When
    /// nil (pinned-scope customization), the user picks a library first.
    let libraryOverride: LibraryIdentifier?
    let onPick: (ItemIdentifier) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        Group {
            if let libraryOverride, libraryOverride.type == expectedLibraryType {
                // Library scope — go straight to this library's items. The
                // caller dismisses the sheet via `collectionPickerType = nil`
                // when `onPick` fires, so we don't dismiss here ourselves.
                CollectionSectionPickerList(library: syntheticLibrary(from: libraryOverride), type: type, onPick: onPick)
            } else if libraryOverride != nil {
                // The scope's library is the wrong type for this collection kind.
                // This shouldn't happen because the add-button row is filtered by
                // library type, but render an explicit state rather than nothing.
                EmptyCollectionView()
                    .navigationTitle(navigationTitle)
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                List {
                    LibraryEnumerator { name, content in
                        Section(name) { content() }
                    } label: { library in
                        if library.id.type == expectedLibraryType {
                            NavigationLink {
                                CollectionSectionPickerList(library: library, type: type, onPick: onPick)
                            } label: {
                                Text(library.name)
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                }
                .navigationTitle(navigationTitle)
                .navigationBarTitleDisplayMode(.inline)
            }
        }
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("action.cancel") { dismiss() }
            }
        }
    }

    private var navigationTitle: String {
        type == .collection
            ? String(localized: "home.customization.addCollection")
            : String(localized: "home.customization.addPlaylist")
    }

    /// Collections live in audiobook libraries; playlists in podcast libraries
    /// (per the server's enum mapping in `Library.swift`).
    private var expectedLibraryType: LibraryMediaType {
        switch type {
        case .collection: .audiobooks
        case .playlist: .podcasts
        }
    }

    /// Build a minimal `Library` from a `LibraryIdentifier` so the lazy loader
    /// can fetch. Only `id.connectionID` / `id.libraryID` are used downstream —
    /// the placeholder name is never shown because the list's title uses the
    /// add-collection/playlist label instead.
    private func syntheticLibrary(from identifier: LibraryIdentifier) -> Library {
        Library(id: identifier.libraryID,
                connectionID: identifier.connectionID,
                name: "",
                type: identifier.type,
                index: 0)
    }
}

private struct CollectionSectionPickerList: View {
    let library: Library
    let type: ItemCollection.CollectionType
    let onPick: (ItemIdentifier) -> Void

    @State private var lazyLoader: LazyLoadHelper<ItemCollection, Void?>

    init(library: Library, type: ItemCollection.CollectionType, onPick: @escaping (ItemIdentifier) -> Void) {
        self.library = library
        self.type = type
        self.onPick = onPick
        _lazyLoader = .init(initialValue: .collections(type))
    }

    var body: some View {
        List {
            if lazyLoader.items.isEmpty {
                if lazyLoader.failed {
                    ErrorView()
                } else if lazyLoader.working {
                    LoadingView()
                } else {
                    EmptyCollectionView()
                }
            } else {
                ForEach(lazyLoader.items) { collection in
                    Button {
                        onPick(collection.id)
                    } label: {
                        HStack {
                            Text(collection.name)
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                    .onAppear {
                        lazyLoader.performLoadIfRequired(collection)
                    }
                }
            }
        }
        .navigationTitle(library.name.isEmpty
                         ? (type == .collection
                            ? String(localized: "home.customization.addCollection")
                            : String(localized: "home.customization.addPlaylist"))
                         : library.name)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            lazyLoader.library = library
            lazyLoader.initialLoad()
        }
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
