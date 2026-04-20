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

#if DEBUG
#Preview {
    NavigationStack {
        HomeCustomizationView(scope: .library(Library.fixture.id), libraryType: .audiobooks)
    }
    .previewEnvironment()
}
#endif
