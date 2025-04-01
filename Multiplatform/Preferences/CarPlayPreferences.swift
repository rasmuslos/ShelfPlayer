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
    
    var body: some View {
        List {
            if let carPlayTabBarLibraries {
                Section {
                    ForEach(carPlayTabBarLibraries) {
                        Text($0.name)
                    }
                } footer: {
                    Text("preferences.carPlay.tabBar.footer")
                }
            }
            
            ForEach(Array(connectionStore.connections.values), id: \.id) { connection in
                Section(connection.friendlyName) {
                    if let libraries = connectionStore.libraries[connection.id] {
                        ForEach(libraries) { library in
                            Button {
                                
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
        .navigationTitle("preferences.carPlay")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func addLibraryToTabBar() {
        
    }
}

#Preview {
    NavigationStack {
        CarPlayPreferences()
    }
    .previewEnvironment()
}
