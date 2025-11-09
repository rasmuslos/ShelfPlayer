//
//  TabBarPreferences.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 17.09.25.
//

import SwiftUI
import ShelfPlayback

struct TabValuePreferences: View {
    @Environment(ConnectionStore.self) private var connectionStore
    
    var body: some View {
        List {
            LibraryEnumerator { name, content in
                Section(name) {
                    content()
                }
            } label: { library in
                let scopes = PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope.available(for: library.type)
                
                if scopes.count == 1, let scope = scopes.first {
                    NavigationLink(library.name, destination: TabValueLibraryPreferences(library: library, scope: scope))
                } else {
                    NavigationLink(library.name) {
                        List {
                            ForEach(scopes) { scope in
                                NavigationLink(scope.label, destination: TabValueLibraryPreferences(library: library, scope: scope))
                            }
                        }
                        .navigationTitle(library.name)
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
    }
}

private struct TabValueLibraryPreferences: View {
    let library: Library
    let scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope
    
    @State private var viewModel: TabValueShadow?
    
    var homeTab: TabValue {
        switch library.type {
            case .audiobooks:
                    .audiobookHome(library)
            case .podcasts:
                    .podcastHome(library)
        }
    }
    var containsHomeTab: Bool {
        viewModel?.tabs.contains { isHomeTab(tabValue: $0) } == true
    }
    
    func isHomeTab(tabValue: TabValue) -> Bool {
        switch tabValue {
            case .audiobookHome, .podcastHome:
                true
            default:
                false
        }
    }
    
    var body: some View {
        List {
            if let viewModel {
                Section {
                    if containsHomeTab {
                        Label(homeTab.label, systemImage: homeTab.image)
                            .foregroundStyle(.primary)
                    }
                    
                    ForEach(viewModel.tabs) { tab in
                        if !isHomeTab(tabValue: tab) {
                            Label(tab.label, systemImage: tab.image)
                                .foregroundStyle(.primary)
                        }
                    }
                    .onMove {
                        viewModel.tabs.move(fromOffsets: $0, toOffset: $1)
                    }
                    .onDelete {
                        for index in $0 {
                            viewModel.tabs.remove(at: index)
                        }
                    }
                }
                .id(viewModel.tabs.count)
                
                Section {
                    ForEach(viewModel.filtered) { tab in
                        Button {
                            viewModel.add(tab: tab)
                        } label: {
                            HStack(spacing: 0) {
                                Label(tab.label, systemImage: tab.image)
                                    .foregroundStyle(.primary)
                                Spacer(minLength: 4)
                                Image(systemName: "plus.circle")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .disabled(viewModel.isFull)
                
                Button("action.reset", role: .destructive) {
                    viewModel.reset()
                }
            } else {
                ProgressView()
                    .task {
                        viewModel = await .init(library: library, scope: scope)
                    }
            }
        }
        .navigationTitle(library.name)
        .environment(\.editMode, .constant(.active))
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("action.save") {
                    viewModel?.save()
                }
            }
        }
        .animation(.smooth, value: viewModel?.tabs)
    }
}

@Observable @MainActor
private final class TabValueShadow {
    let MAXIMUM_TAB_COUNT = 5
    
    let library: Library
    let scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope
    
    var tabs: [TabValue]
    var available: [TabValue]
    
    var isLoading = false
    var notifyError = false
    
    init(library: Library, scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope) async {
        self.library = library
        self.scope = scope
        
        tabs = await PersistenceManager.shared.customization.configuredTabs(for: library, scope: scope)
        available = PersistenceManager.shared.customization.availableTabs(for: library, scope: scope)
    }
    
    var filtered: [TabValue] {
        available.filter { !tabs.contains($0) }
    }
    var isFull: Bool {
        if scope == .library {
           false
        } else {
            tabs.count >= MAXIMUM_TAB_COUNT
        }
    }
    
    func add(tab: TabValue) {
        guard !isFull else {
            return
        }
        
        tabs.append(tab)
    }
    func reset() {
        tabs = PersistenceManager.shared.customization.defaultTabs(for: library, scope: scope)
    }
    
    func save() {
        Task {
            do {
                try await PersistenceManager.shared.customization.setConfiguredTabs(tabs, for: library, scope: scope)
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
