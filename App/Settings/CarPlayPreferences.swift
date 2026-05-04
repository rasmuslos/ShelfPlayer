//
//  CarPlayPreferences.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 01.04.25.
//

import SwiftUI
import ShelfPlayback

struct CarPlayPreferences: View {
    @State private var carPlayTabBarLibraries: [Library]? = AppSettings.shared.carPlayTabBarLibraries
    @State private var carPlayShowOtherLibraries: Bool = AppSettings.shared.carPlayShowOtherLibraries

    private var selected: [Library] { carPlayTabBarLibraries ?? [] }
    private var selectedIDs: Set<LibraryIdentifier> { Set(selected.map(\.id)) }

    private var showTabBarLimitWarning: Bool {
        let additionalTabs = 1
        return (selected.count + additionalTabs) > 5
    }

    var body: some View {
        List {
            SettingsPageHeader(title: "preferences.carPlay", systemImage: "car.fill", color: .green)

            if !selected.isEmpty {
                Section {
                    ForEach(selected) { library in
                        Label(library.name, systemImage: library.icon)
                    }
                    .onMove(perform: move)
                    .onDelete(perform: remove)
                } header: {
                    Text("preferences.carPlay.tabBar")
                } footer: {
                    if showTabBarLimitWarning {
                        Text("preferences.carPlay.tabBar.warning")
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
                if !selectedIDs.contains(library.id) {
                    AddRow(systemImage: library.icon, title: library.name) {
                        add(library)
                    }
                }
            }

            Section {
                Toggle("carPlay.otherLibraries", isOn: $carPlayShowOtherLibraries)
                    .onChange(of: carPlayShowOtherLibraries) { AppSettings.shared.carPlayShowOtherLibraries = carPlayShowOtherLibraries }
            }
        }
        .navigationTitle("preferences.carPlay")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.editMode, .constant(.active))
        .animation(.smooth, value: carPlayTabBarLibraries)
    }

    private func add(_ library: Library) {
        withAnimation {
            var list = selected
            guard !list.contains(where: { $0.id == library.id }) else { return }
            list.append(library)
            persist(list)
        }
    }

    private func move(from source: IndexSet, to destination: Int) {
        var list = selected
        list.move(fromOffsets: source, toOffset: destination)
        persist(list)
    }

    private func remove(at offsets: IndexSet) {
        var list = selected
        list.remove(atOffsets: offsets)
        persist(list)
    }

    private func persist(_ list: [Library]) {
        carPlayTabBarLibraries = list.isEmpty ? nil : list
        AppSettings.shared.carPlayTabBarLibraries = carPlayTabBarLibraries
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        CarPlayPreferences()
    }
    .previewEnvironment()
}
#endif
