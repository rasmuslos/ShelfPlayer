//
//  TabValuePreferences.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 17.09.25.
//

import SwiftUI
import ShelfPlayback

struct TabValuePreferences: View {
    @Environment(ConnectionStore.self) private var connectionStore

    @Bindable private var settings = AppSettings.shared

    private var isMultiLibraryPinned: Bool {
        settings.pinnedTabValues.contains(.multiLibrary)
    }

    var body: some View {
        List {
            SettingsPageHeader(title: "preferences.tabs", systemImage: "rectangle.2.swap", color: .purple)

            Section {
                Toggle("settings.hideSearchTab", isOn: $settings.hideSearchTab)
            } footer: {
                Text("settings.hideSearchTab.footer")
            }

            // Mirror the customization entries surfaced in the
            // CompactLibraryPicker settings menu so every destination is
            // reachable from the settings sheet too.
            Section {
                NavigationLink(destination: CustomTabValuesPreferences()) {
                    Label("preferences.pinnedTabs", systemImage: "pin.fill")
                }
                // Übersicht customization is only meaningful when the
                // multi-library tab is actually visible in the tab bar.
                if isMultiLibraryPinned {
                    NavigationLink(destination: HomeCustomizationView(scope: .multiLibrary, libraryType: nil)) {
                        Label("home.customization.multiLibraryTitle", systemImage: "slider.horizontal.3")
                    }
                }
            }

            LibraryEnumerator { name, content in
                Section {
                    content()
                } header: {
                    Text(name)
                }
            } label: { library in
                let scopes = PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope.available(for: library.id.type)

                DisclosureGroup(library.name) {
                    NavigationLink(destination: HomeCustomizationView(scope: .library(library.id), libraryType: library.id.type)) {
                        Label("home.customization.title", systemImage: "slider.horizontal.3")
                    }
                    ForEach(scopes) { scope in
                        NavigationLink(destination: TabValueLibraryPreferences(library: library, scope: scope)) {
                            Label(scope.label, systemImage: "rectangle.2.swap")
                        }
                    }
                }
            }
        }
        .navigationTitle("preferences.tabs")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.smooth, value: connectionStore.connections.map(\.id))
        .animation(.smooth, value: isMultiLibraryPinned)
    }
}

struct TabValueLibraryPreferences: View {
    let library: Library
    let scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope

    @State private var viewModel: TabValueShadow?

    var body: some View {
        List {
            if let viewModel {
                Section {
                    ForEach(viewModel.active) { tab in
                        Label(tab.label, systemImage: tab.image)
                    }
                    .onMove { viewModel.move(from: $0, to: $1) }
                    .onDelete { viewModel.remove(at: $0) }
                }

                let unselected = viewModel.unselected
                if !unselected.isEmpty {
                    Section {
                        // Namespace the row identity so it cannot collide with
                        // the active section's ForEach. Sharing TabValue.id
                        // across both ForEaches makes SwiftUI treat tap-to-add
                        // as a cross-section identity move, which strips the
                        // EditMode decorations off the inserted row.
                        ForEach(unselected, id: \.addRowID) { tab in
                            AddRow(systemImage: tab.image, title: tab.label) {
                                viewModel.add(tab.id)
                            }
                            .disabled(viewModel.isFull)
                            .opacity(viewModel.isFull ? 0.4 : 1)
                        }
                    } header: {
                        Text("home.customization.addSection")
                    }
                }
            } else {
                ProgressView()
                    .task {
                        viewModel = await .init(library: library, scope: scope)
                    }
            }
        }
        .navigationTitle(library.name)
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Menu {
                    Button(role: .destructive) {
                        viewModel?.reset()
                    } label: {
                        Label("action.reset", systemImage: "arrow.counterclockwise")
                    }
                    .disabled(viewModel == nil)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .animation(.smooth, value: viewModel?.activeIDs)
    }
}

@Observable @MainActor
private final class TabValueShadow {
    let MAXIMUM_TAB_COUNT = 4

    let library: Library
    let scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope

    var activeIDs = [TabValue.ID]()
    /// Master list of every tab available for this library+scope, in the
    /// canonical order defined by the app. Used as a lookup table and to
    /// determine the default order of not-yet-added tabs.
    let available: [TabValue]

    init(library: Library, scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope) async {
        self.library = library
        self.scope = scope

        available = PersistenceManager.shared.customization.availableTabs(for: library.id, scope: scope)

        let configured = await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: scope)
        activeIDs = configured.map(\.id)
    }

    var isFull: Bool {
        if scope == .library {
           false
        } else {
            activeIDs.count >= MAXIMUM_TAB_COUNT
        }
    }

    var active: [TabValue] {
        activeIDs.compactMap { id in
            available.first { $0.id == id }
        }
    }

    var unselected: [TabValue] {
        let selected = Set(activeIDs)
        return available.filter { !selected.contains($0.id) }
    }

    func add(_ tabID: TabValue.ID) {
        guard !isFull, !activeIDs.contains(tabID) else { return }
        activeIDs.append(tabID)
        persist()
    }

    func remove(at offsets: IndexSet) {
        let ids = offsets.map { active[$0].id }
        activeIDs.removeAll { ids.contains($0) }
        persist()
    }

    func move(from source: IndexSet, to destination: Int) {
        activeIDs.move(fromOffsets: source, toOffset: destination)
        persist()
    }

    func reset() {
        Task {
            try? await PersistenceManager.shared.customization.setConfiguredTabs(nil, for: library.id, scope: scope)
            let configured = await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: scope)
            activeIDs = configured.map(\.id)
        }
    }

    private func persist() {
        let snapshot = active
        Task {
            try? await PersistenceManager.shared.customization.setConfiguredTabs(snapshot, for: library.id, scope: scope)
        }
    }
}

/// Shared row used by the plus-based add sections in the tab-value and
/// CarPlay library pickers. Matches the styling used in
/// `HomeCustomizationView` so the three customization flows read the same.
struct AddRow: View {
    let systemImage: String
    let title: String
    let action: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "plus.circle.fill")
                .foregroundStyle(.white, .green)
                .font(.title3)
            Image(systemName: systemImage)
                .foregroundStyle(Color.accentColor)
                .frame(width: 22)
            Text(title)
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
        .contentShape(.rect)
        .onTapGesture(perform: action)
    }
}

private extension TabValue {
    var addRowID: String { "add_\(id)" }
}

extension PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope {
    var label: LocalizedStringKey {
        switch self {
            case .library:
                "panel.library"
            case .tabBar:
                "preferences.tabs"
            case .sidebar:
                fatalError()
        }
    }
}

struct CustomTabValuesPreferences: View {
    @State private var pinnedTabValues: [TabValue] = AppSettings.shared.pinnedTabValues
    // Programmatic navigation: NavigationLink is non-tappable inside an
    // edit-mode List, so the multi-library customization row drives push via
    // an item-bound destination instead.
    @State private var customizingHomeScope: HomeScope?

    private var isMultiLibraryPinned: Bool {
        pinnedTabValues.contains(.multiLibrary)
    }

    var body: some View {
        List {
            if !pinnedTabValues.isEmpty {
                Section {
                    ForEach(pinnedTabValues) { tab in
                        Label(tab.label, systemImage: tab.image)
                    }
                    .onMove(perform: move)
                    .onDelete(perform: remove)
                }
            }

            if isMultiLibraryPinned {
                Section {
                    Button {
                        customizingHomeScope = .multiLibrary
                    } label: {
                        HStack {
                            Label("home.customization.title", systemImage: "slider.horizontal.3")
                                .foregroundStyle(.primary)
                            Spacer(minLength: 0)
                            Image(systemName: "chevron.right")
                                .font(.footnote.weight(.semibold))
                                .foregroundStyle(.tertiary)
                        }
                        .contentShape(.rect)
                    }
                    .buttonStyle(.plain)
                } footer: {
                    Text("home.customization.multiLibrarySectionFooter")
                }
            } else {
                Section {
                    AddRow(systemImage: TabValue.multiLibrary.image, title: TabValue.multiLibrary.label) {
                        add(.multiLibrary)
                    }
                } header: {
                    Text("home.customization.multiLibrarySectionHeader")
                } footer: {
                    Text("home.customization.multiLibrarySectionFooter")
                }
            }

            LibraryEnumerator { name, content in
                Section {
                    content()
                } header: {
                    Text(name)
                }
            } label: { library in
                let available = PersistenceManager.shared.customization.availableTabs(for: library.id, scope: .tabBar)
                let unselected = available.filter { !pinnedTabValues.contains(.custom($0, library.name)) }

                if !unselected.isEmpty {
                    DisclosureGroup(library.name) {
                        ForEach(unselected) { tab in
                            AddRow(systemImage: tab.image, title: tab.label) {
                                add(.custom(tab, library.name))
                            }
                        }
                    }
                }
            }
        }
        .navigationTitle("preferences.pinnedTabs")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .animation(.smooth, value: pinnedTabValues)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(role: .destructive) {
                        reset()
                    } label: {
                        Label("action.reset", systemImage: "arrow.counterclockwise")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .navigationDestination(item: $customizingHomeScope) { scope in
            HomeCustomizationView(scope: scope, libraryType: nil)
        }
    }

    private func reset() {
        withAnimation {
            pinnedTabValues = []
            AppSettings.shared.pinnedTabValues = pinnedTabValues
        }
    }

    private func add(_ tab: TabValue) {
        withAnimation {
            guard !pinnedTabValues.contains(tab) else { return }
            pinnedTabValues.append(tab)
            AppSettings.shared.pinnedTabValues = pinnedTabValues
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        pinnedTabValues.move(fromOffsets: source, toOffset: destination)
        AppSettings.shared.pinnedTabValues = pinnedTabValues
    }

    private func remove(at offsets: IndexSet) {
        pinnedTabValues.remove(atOffsets: offsets)
        AppSettings.shared.pinnedTabValues = pinnedTabValues
    }
}

#if DEBUG
#Preview("TabValuePreferences") {
    NavigationStack {
        TabValuePreferences()
    }
    .previewEnvironment()
}

#Preview("TabValueLibraryPreferences") {
    NavigationStack {
        TabValueLibraryPreferences(library: .fixture, scope: .tabBar)
    }
    .previewEnvironment()
}

#Preview("AddRow") {
    List {
        AddRow(systemImage: "house.fill", title: "Home") {}
    }
}

#Preview("CustomTabValuesPreferences") {
    NavigationStack {
        CustomTabValuesPreferences()
    }
    .previewEnvironment()
}
#endif
