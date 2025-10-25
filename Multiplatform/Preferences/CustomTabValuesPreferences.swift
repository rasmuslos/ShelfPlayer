//
//  CustomTabValuesPreferences.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.10.25.
//

import SwiftUI
import ShelfPlayback

struct CustomTabValuesPreferences: View {
    @Default(.customTabValues) private var customTabValues
    
    var body: some View {
        List {
            Section {
                ForEach(customTabValues) { tab in
                    Label(tab.library.name, systemImage: tab.image)
                }
                .onMove {
                    customTabValues.move(fromOffsets: $0, toOffset: $1)
                }
                .onDelete {
                    customTabValues.remove(atOffsets: $0)
                }
            }
            
            Section {
                Button("action.reset", role: .destructive) {
                    customTabValues.removeAll()
                }
            }
            
            LibraryEnumerator { name, content in
                Section {
                    Text(name)
                        .bold()
                        .listRowBackground(Color.clear)
                }
                
                content()
            } label: { library in
                Section {
                    ForEach(PersistenceManager.shared.customization.availableTabs(for: library, scope: .tabBar)) { tab in
                        let customTab: TabValue = .custom(tab)
                        
                        if !customTabValues.contains(customTab) {
                            Button {
                                guard !customTabValues.contains(customTab) else {
                                    return
                                }
                                
                                customTabValues.append(customTab)
                            } label: {
                                HStack(spacing: 0) {
                                    Label(tab.label, systemImage: tab.image)
                                    
                                    Spacer(minLength: 8)
                                    
                                    Image(systemName: "plus.circle")
                                        .foregroundStyle(Color.accentColor)
                                }
                                .contentShape(.rect)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                } header: {
                    Text(library.name)
                }
            }
        }
        .environment(\.editMode, .constant(.active))
        .navigationTitle("preferences.customNavigation")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.smooth, value: customTabValues)
    }
}

#if DEBUG
#Preview {
    CustomTabValuesPreferences()
        .previewEnvironment()
}
#endif
