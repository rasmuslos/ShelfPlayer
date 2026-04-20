//
//  LibraryPicker.swift
//  ShelfPlayer
//

import SwiftUI
import ShelfPlayback

struct LibraryPicker: View {
    @Environment(TabRouterViewModel.self) private var tabRouterViewModel
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(Satellite.self) private var satellite

    var callback: (() -> Void)? = nil

    private var connectionIDs: [ItemIdentifier.ConnectionID] {
        Array(tabRouterViewModel.connectionLibraries.keys.sorted())
    }

    private func libraryToggleBinding(for library: Library) -> Binding<Bool> {
        .init {
            tabRouterViewModel.tabValue?.libraryID == library.id
        } set: { _ in
            tabRouterViewModel.selectCompact(libraryID: library.id)
            callback?()
        }
    }

    private var hiddenLibraries: Set<LibraryIdentifier> { AppSettings.shared.hiddenLibraries }

    var body: some View {
        ForEach(connectionIDs, id: \.hashValue) { connectionID in
            if let connection = connectionStore.connections.first(where: { $0.id == connectionID }), let libraries = tabRouterViewModel.connectionLibraries[connectionID] {
                let visible = libraries.filter { !hiddenLibraries.contains($0.id) }

                if !visible.isEmpty {
                    Section(connection.name) {
                        ForEach(visible) { library in
                            Toggle(library.name, systemImage: library.icon, isOn: libraryToggleBinding(for: library))
                        }
                    }
                }
            }
        }
    }
}

extension Library {
    var icon: String {
        switch id.type {
        case .audiobooks:
            "headphones"
        case .podcasts:
            "antenna.radiowaves.left.and.right"
        }
    }
}
