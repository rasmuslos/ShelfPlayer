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

            Section {
                LibraryEnumerator { name, content in
                    Section(name) {
                        content()
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
            }

            Section {
                NavigationLink("panel.home") {
                    CustomTabValuesPreferences()
                }
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

    func isActive(tabID: TabValue.ID) -> Bool {
        viewModel?.activeIDs.contains(tabID) ?? false
    }
    func binding(for tabID: TabValue.ID) -> Binding<Bool> {
        Binding {
            isActive(tabID: tabID)
        } set: {
            guard $0 != isActive(tabID: tabID) else {
                return
            }

            if let viewModel, let index = viewModel.activeIDs.firstIndex(of: tabID) {
                viewModel.activeIDs.remove(at: index)
            } else if viewModel?.isFull == false {
                viewModel?.activeIDs.append(tabID)
            }

            viewModel?.transferOrder()
        }
    }

    @ViewBuilder
    private func label(tab: TabValue) -> some View {
        Label(tab.label, systemImage: tab.image)
            .foregroundStyle(.primary)
    }

    var body: some View {
        List {
            if let viewModel {
                ForEach(viewModel.available) { tab in
                    Toggle(isOn: binding(for: tab.id)) {
                        label(tab: tab)
                    }
                    .disabled(viewModel.isFull && !isActive(tabID: tab.id))
                }
                .onMove {
                    viewModel.available.move(fromOffsets: $0, toOffset: $1)
                    viewModel.transferOrder()
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
    var available: [TabValue]

    var isLoading = false
    var notifyError = false

    init(library: Library, scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope) async {
        self.library = library
        self.scope = scope

        let available = PersistenceManager.shared.customization.availableTabs(for: library.id, scope: scope)

        let configured = await PersistenceManager.shared.customization.configuredTabs(for: library.id, scope: scope)

        let missing = available.filter { !configured.contains($0) }

        self.available = configured + missing
        setActive(tabs: configured)
    }

    var isFull: Bool {
        if scope == .library {
           false
        } else {
            activeIDs.count >= MAXIMUM_TAB_COUNT
        }
    }

    func setActive(tabs: [TabValue]) {
        self.activeIDs = tabs.map(\.id)
    }
    var active: [TabValue] {
        activeIDs.compactMap { id in
            available.first { $0.id == id }
        }
    }

    func transferOrder() {
        let tabIDs = activeIDs
        activeIDs = available.compactMap { tabIDs.contains($0.id) ? $0.id : nil }
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

    private var pinnedHomeTabs: [TabValue] {
        pinnedTabValues.filter { tab in
            if case .custom(let inner, _) = tab {
                switch inner {
                case .audiobookHome, .podcastHome:
                    return true
                default:
                    return false
                }
            }
            return false
        }
    }

    var body: some View {
        List {
            if !pinnedHomeTabs.isEmpty {
                Section {
                    ForEach(pinnedHomeTabs) { tab in
                        if case .custom(let inner, _) = tab {
                            NavigationLink {
                                HomeCustomizationView(scope: .pinned(inner.id), libraryType: nil)
                            } label: {
                                Label(tab.label, systemImage: "slider.horizontal.3")
                                    .foregroundStyle(.primary)
                            }
                        }
                    }
                } header: {
                    Text("home.customization.pinnedSectionHeader")
                }
            }

            Section {
                LibraryEnumerator { name, content in
                    Section(name) {
                        content()
                    }
                } label: { library in
                    ForEach(PersistenceManager.shared.customization.availableTabs(for: library.id, scope: .tabBar)) { tab in
                        let customTab: TabValue = .custom(tab, library.name)

                        Toggle(isOn: pinnedBinding(for: customTab)) {
                            Label(tab.label, systemImage: tab.image)
                                .foregroundStyle(.primary)
                        }
                    }
                }
            }
        }
        .navigationTitle("panel.home")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.smooth, value: pinnedTabValues)
    }

    private func pinnedBinding(for tab: TabValue) -> Binding<Bool> {
        Binding {
            pinnedTabValues.contains(tab)
        } set: { pinned in
            withAnimation {
                if pinned {
                    guard !pinnedTabValues.contains(tab) else { return }
                    pinnedTabValues.append(tab)
                } else {
                    pinnedTabValues.removeAll { $0 == tab }
                }
                AppSettings.shared.pinnedTabValues = pinnedTabValues
            }
        }
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
