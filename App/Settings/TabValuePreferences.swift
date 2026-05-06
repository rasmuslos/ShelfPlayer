//
//  TabValuePreferences.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 17.09.25.
//

import SwiftUI
import ShelfPlayback

struct TabValuePreferences: View {
    var body: some View {
        List {
            SettingsPageHeader(title: "preferences.tabs", systemImage: "rectangle.2.swap", color: .purple)

            LibraryEnumerator { name, content in
                Section {
                    content()
                } header: {
                    Text(name)
                }
            } label: { library in
                let scopes = PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope.available(for: library.id.type)

                if scopes.count == 1, let scope = scopes.first {
                    NavigationLink(library.name, destination: TabValueLibraryPreferences(library: library, scope: scope))
                } else {
                    DisclosureGroup(library.name) {
                        ForEach(scopes) { scope in
                            NavigationLink(scope.label, destination: TabValueLibraryPreferences(library: library, scope: scope))
                        }
                    }
                }
            }

            Section {
                NavigationLink("panel.home") {
                    CustomTabValuesPreferences()
                }
            } header: {
                Text("home.customization.title")
            }
        }
        .navigationTitle("preferences.tabs")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct TabValueLibraryPreferences: View {
    let library: Library
    let scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope

    var callback: (() -> Void)? = nil

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
                        ForEach(unselected) { tab in
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
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") {
                    viewModel?.save {
                        callback?()
                    }
                }
            }
        }
        .animation(.smooth, value: viewModel?.activeIDs)
    }
}

@Observable @MainActor
private final class TabValueShadow {
    let MAXIMUM_TAB_COUNT = 5

    let library: Library
    let scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope

    var activeIDs = [TabValue.ID]()
    /// Master list of every tab available for this library+scope, in the
    /// canonical order defined by the app. Used as a lookup table and to
    /// determine the default order of not-yet-added tabs.
    let available: [TabValue]

    var isLoading = false
    var notifyError = false

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
    }

    func remove(at offsets: IndexSet) {
        let ids = offsets.map { active[$0].id }
        activeIDs.removeAll { ids.contains($0) }
    }

    func move(from source: IndexSet, to destination: Int) {
        activeIDs.move(fromOffsets: source, toOffset: destination)
    }

    func save(callback: @escaping () -> Void) {
        Task {
            do {
                try await PersistenceManager.shared.customization.setConfiguredTabs(active, for: library.id, scope: scope)
                callback()
            } catch {
                notifyError.toggle()
            }
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
                    NavigationLink(value: HomeScope.multiLibrary) {
                        Label("home.customization.title", systemImage: "slider.horizontal.3")
                    }
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
        .navigationTitle("panel.home")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .animation(.smooth, value: pinnedTabValues)
        .navigationDestination(for: HomeScope.self) { scope in
            HomeCustomizationView(scope: scope, libraryType: nil)
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
#Preview {
    NavigationStack {
        TabValuePreferences()
    }
    .previewEnvironment()
}

#Preview {
    NavigationStack {
        TabValueLibraryPreferences(library: .fixture, scope: .tabBar)
    }
    .previewEnvironment()
}
#endif
