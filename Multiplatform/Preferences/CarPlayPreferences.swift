//
//  CarPlayPreferences.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 01.04.25.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct CarPlayPreferences: View {
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(Satellite.self) private var satellite
    
    @Default(.carPlayTabBarLibraries) private var carPlayTabBarLibraries
    
    private var showOtherLibrariesInfo: Bool {
        guard let carPlayTabBarLibraries else {
            return true
        }
        
        let totalLibraryCount = connectionStore.libraries.map { $0.1.count }.reduce(0, +)
        
        return carPlayTabBarLibraries.count != totalLibraryCount
    }
    private var showTabBarLimitWarning: Bool {
        guard let carPlayTabBarLibraries else {
            return false
        }
        
        var additionalTabs = 1
        
        if showOtherLibrariesInfo {
            additionalTabs += 1
        }
        
        return (carPlayTabBarLibraries.count + additionalTabs) > 5
    }
    
    var body: some View {
        List {
            Section {
                Text("preferences.carPlay.tabBar.downloaded")
                    .foregroundStyle(.secondary)
                
                if let carPlayTabBarLibraries {
                    ForEach(carPlayTabBarLibraries) {
                        Text($0.name)
                    }
                    .onMove {
                        moveLibrary(from: $0, to: $1)
                    }
                    .onDelete {
                        for index in $0 {
                            removeLibraryFromTabBar(at: index)
                        }
                    }
                    
                    if showOtherLibrariesInfo {
                        Text("preferences.carPlay.tabBar.additionalLibraries")
                            .foregroundStyle(.secondary)
                    }
                }
            } footer: {
                Text("preferences.carPlay.tabBar.footer")
            }
            
            if showTabBarLimitWarning {
                Text("preferences.carPlay.tabBar.warning")
                    .foregroundStyle(.blue)
            }
            
            ForEach(Array(connectionStore.connections.values), id: \.id) { connection in
                Section(connection.friendlyName) {
                    if let libraries = connectionStore.libraries[connection.id] {
                        ForEach(libraries) { library in
                            Button {
                                addLibraryToTabBar(library)
                            } label: {
                                HStack(spacing: 0) {
                                    Text(library.name)
                                    
                                    Spacer(minLength: 8)
                                    
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(Color.accentColor)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    } else {
                        ProgressIndicator()
                    }
                }
            }
            
            Button("action.reset", role: .destructive) {
                Defaults.reset(.carPlayTabBarLibraries)
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("preferences.carPlay")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addLibraryToTabBar(_ library: Library) {
        guard carPlayTabBarLibraries?.contains(library) != true else {
            return
        }
        
        withAnimation {
            if carPlayTabBarLibraries == nil {
                carPlayTabBarLibraries = [library]
            } else {
                carPlayTabBarLibraries?.append(library)
            }
        }
    }
    private func moveLibrary(from: IndexSet, to: Int) {
        carPlayTabBarLibraries?.move(fromOffsets: from, toOffset: to)
    }
    private func removeLibraryFromTabBar(at index: Int) {
        carPlayTabBarLibraries?.remove(at: index)
        
        if carPlayTabBarLibraries?.isEmpty == true {
            carPlayTabBarLibraries = nil
        }
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
