//
//  CustomTabValuesPreferences.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.10.25.
//

import SwiftUI
import ShelfPlayback

struct CustomTabValuesPreferences: View {
    @Default(.pinnedTabValues) private var pinnedTabValues
    
    var body: some View {
        List {
            Section {
                ForEach(pinnedTabValues) { tab in
                    Label(tab.label, systemImage: tab.image)
                        .foregroundStyle(.primary)
                }
                .onMove {
                    pinnedTabValues.move(fromOffsets: $0, toOffset: $1)
                }
                .onDelete {
                    pinnedTabValues.remove(atOffsets: $0)
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
                    ForEach(PersistenceManager.shared.customization.availableTabs(for: library.id, scope: .tabBar)) { tab in
                        let customTab: TabValue = .custom(tab, library.name)
                        
                        if !pinnedTabValues.contains(customTab) {
                            Button {
                                guard !pinnedTabValues.contains(customTab) else {
                                    return
                                }
                                
                                pinnedTabValues.append(customTab)
                            } label: {
                                HStack(spacing: 0) {
                                    Label(tab.label, systemImage: tab.image)
                                        .foregroundStyle(.primary)
                                    
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
        .navigationTitle("panel.home")
        .navigationBarTitleDisplayMode(.inline)
        .animation(.smooth, value: pinnedTabValues)
    }
}

#if DEBUG
#Preview {
    CustomTabValuesPreferences()
        .previewEnvironment()
}
#endif
