//
//  LibraryVisibilityPreferences.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI
import ShelfPlayback

struct LibraryVisibilityPreferences: View {
    @State private var hiddenLibraries = AppSettings.shared.hiddenLibraries

    var body: some View {
        List {
            SettingsPageHeader(
                title: "preferences.hiddenLibraries",
                systemImage: "eye.slash.fill",
                color: .gray,
                subtitle: "preferences.hiddenLibraries.footer"
            )

            Section {
                LibraryEnumerator { name, content in
                    Section(name) {
                        content()
                    }
                } label: { library in
                    let isHidden = hiddenLibraries.contains(library.id)

                    Toggle(library.name, systemImage: library.icon, isOn: .init {
                        !isHidden
                    } set: { visible in
                        if visible {
                            hiddenLibraries.remove(library.id)
                        } else {
                            hiddenLibraries.insert(library.id)
                        }

                        AppSettings.shared.hiddenLibraries = hiddenLibraries
                        TabEventSource.shared.invalidateTabs.send()
                    })
                }
            }
        }
        .navigationTitle("preferences.hiddenLibraries")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.smooth, value: hiddenLibraries)
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        LibraryVisibilityPreferences()
    }
    .previewEnvironment()
}
#endif
