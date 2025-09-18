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
            ForEach(connectionStore.connections) { connection in
                Section(connection.name) {
                    if let libraries = connectionStore.libraries[connection.id] {
                        ForEach(libraries) { library in
                            let scopes = PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope.available(for: library.type)
                            
                            if scopes.count == 1, let scope = scopes.first {
                                NavigationLink(library.name, destination: TabValueLibraryPreferences(library: library, scope: scope))
                            } else {
                                Menu(library.name) {
                                    ForEach(scopes, id: \.rawValue) { scope in
                                        NavigationLink(String("\(library.name): \(scope.label)"), destination: TabValueLibraryPreferences(library: library, scope: scope))
                                    }
                                }
                            }
                        }
                    } else {
                        ProgressView()
                    }
                }
            }
        }
    }
}

private struct TabValueLibraryPreferences: View {
    let library: Library
    let scope: PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope
    
    @State private var viewModel: TabValueShadow?
    
    var body: some View {
        List {
            if let viewModel {
                
            } else {
                ProgressView()
            }
        }
        .navigationTitle(library.name)
    }
}

@Observable @MainActor
private final class TabValueShadow {
    var tabs: [TabValue]
    
    init() async {
        tabs = []
    }
}

extension PersistenceManager.CustomizationSubsystem.TabValueCustomizationScope {
    var label: String {
        ""
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
        TabValueLibraryPreferences(library: .init(id: "fixture", connectionID: "fixture", name: "Fixture", type: .podcasts, index: 0), scope: .tabBar)
    }
    .previewEnvironment()
}
#endif
