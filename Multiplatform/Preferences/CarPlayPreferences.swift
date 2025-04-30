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
    @Default(.carPlayShowListenNow) private var carPlayShowListenNow
    @Default(.carPlayShowOtherLibraries) private var carPlayShowOtherLibraries
    
    private var shouldShowOtherLibraries: Bool {
        guard let carPlayTabBarLibraries else {
            return true
        }
        
        let totalLibraryCount = connectionStore.libraries.map { $0.1.count }.reduce(0, +)
        
        return carPlayTabBarLibraries.count != totalLibraryCount
    }
    private var areOtherLibrariesVisible: Bool {
        carPlayShowOtherLibraries && shouldShowOtherLibraries
    }
    
    private var showTabBarLimitWarning: Bool {
        guard let carPlayTabBarLibraries else {
            return false
        }
        
        var additionalTabs = 1
        
        if areOtherLibrariesVisible {
            additionalTabs += 1
        }
        
        return (carPlayTabBarLibraries.count + additionalTabs) > 5
    }
    
    var body: some View {
        List {
            Section {
                Toggle("panel.listenNow", isOn: $carPlayShowListenNow)
                
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
                }
                
                if shouldShowOtherLibraries {
                    Toggle("carPlay.otherLibraries", isOn: $carPlayShowOtherLibraries)
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
                            .disabled(carPlayTabBarLibraries?.contains(library) ?? false)
                        }
                    } else {
                        ProgressView()
                    }
                }
            }
            
            Button("action.reset", role: .destructive) {
                Defaults.reset(.carPlayTabBarLibraries)
                Defaults.reset(.carPlayShowListenNow)
                Defaults.reset(.carPlayShowOtherLibraries)
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
