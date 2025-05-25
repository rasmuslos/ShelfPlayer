//
//  DebugPreferences.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.05.25.
//

import SwiftUI
import ShelfPlayerKit

struct DebugPreferences: View {
    #if DEBUG
    @State private var _itemID: String = "1::audiobook::Mn5Uwo+RZPPRUFZcewyMSWva5dUcftExIlOdw1ULo5o=::44e2d00a-402a-42ae-9bd3-3f339df44aef::75a7eaa0-0aed-46aa-8cb1-b5f43dbae985"
    
    private var itemID: ItemIdentifier {
        ItemIdentifier(_itemID)
    }
    #endif
    
    var body: some View {
        List {
            #if DEBUG
            Section(String("Item")) {
                TextField(String("ItemID"), text: $_itemID)
                
                Button(String("Navigate")) {
                    itemID.navigate()
                }
                Button(String("Create playback sessions")) {
                    Task {
                        await createDebugListeningSession(for: itemID)
                    }
                }
            }
            #endif
            
            Section {
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer")!) {
                    Label("preferences.github", systemImage: "chevron.left.forwardslash.chevron.right")
                }
                Link(destination: URL(string: "https://github.com/rasmuslos/ShelfPlayer/Support.md")!) {
                    Label("preferences.support", systemImage: "lifepreserver")
                }
                
                CreateLogArchiveButton()
            }
            .foregroundStyle(.primary)
            
            Section {
                Text("preferences.version \(ShelfPlayerKit.clientVersion) \(ShelfPlayerKit.clientBuild) \(ShelfPlayerKit.enableCentralized ? "C" : "L")")
                Text("preferences.version.database \(PersistenceManager.shared.modelContainer.schema.version.description) \(PersistenceManager.shared.modelContainer.configurations.map { $0.name }.joined(separator: ", "))")
            }
            .foregroundStyle(.secondary)
            .font(.caption)
        }
        .navigationTitle("preferences.debug")
    }
}

#if DEBUG
private func createDebugListeningSession(for itemID: ItemIdentifier) async {
    for i in 1..<50 {
        let i = Double(i)
        try! await ABSClient[itemID.connectionID].createListeningSession(itemID: itemID, timeListened: 400 + i, startTime: i * 4, currentTime: i * 5, started: .now, updated: .now)
    }
}

#Preview {
    NavigationStack {
        DebugPreferences()
    }
    .previewEnvironment()
}
#endif
