//
//  EditCollectionSheet.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.07.25.
//

import SwiftUI
import ShelfPlayback

struct EditCollectionSheet: View {
    @Environment(Satellite.self) private var satellite
    
    let collection: ItemCollection
    
    @State private var name: String
    @State private var description: String
    
    @State private var items: [Item]
    
    @State private var isLoading = false
    @State private var notifyError = false
    
    init(collection: ItemCollection) {
        self.collection = collection
        
        _name = .init(initialValue: collection.name)
        _description = .init(initialValue: collection.description ?? "")
        _items = .init(initialValue: collection.items)
    }
    
    var body: some View {
        NavigationStack {
            List {
                TextField(collection.name, text: $name)
                TextField(collection.description ?? String(localized: "item.description"), text: $description, axis: .vertical)
                    .lineLimit(3...7)
                
                Section {
                    ForEach(items) {
                        ItemCompactRow(item: $0, context: .collectionEdit)
                            .modifier(ItemStatusModifier(item: $0, hoverEffect: nil, isInteractive: false))
                    }
                    .onMove {
                        items.move(fromOffsets: $0, toOffset: $1)
                    }
                    .onDelete {
                        items.remove(atOffsets: $0)
                    }
                }
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("collection.edit.headline")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        satellite.dismissSheet()
                    }
                    .disabled(isLoading)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("action.save") {
                        save() {
                            satellite.dismissSheet()
                        }
                    }
                    .disabled(isLoading)
                }
            }
        }
        .interactiveDismissDisabled()
        .sensoryFeedback(.error, trigger: notifyError)
    }
    
    private nonisolated func save(_ callback: @MainActor @escaping () -> Void) {
        Task {
            await MainActor.withAnimation {
                isLoading = true
            }
            
            let name = await name
            var description: String? = await description
                
            description = description?.trimmingCharacters(in: .whitespacesAndNewlines)
            
            if description?.isEmpty == true {
                description = nil
            }
            
            do {
                if collection.name != name || collection.description != description {
                    try await ABSClient[collection.id.connectionID].updateCollection(collection.id, name: name, description: description)
                }
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
            
            let items = await items
            
            do {
                if collection.items != items {
                    try await ABSClient[collection.id.connectionID].updateCollection(collection.id, itemIDs: items.map(\.id))
                }
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
            
            try? await ShelfPlayer.refreshItem(itemID: collection.id)
            await RFNotification[.collectionChanged].send(payload: collection.id)
            
            await MainActor.withAnimation {
                isLoading = false
                callback()
            }
        }
    }
}

#if DEBUG
#Preview {
    EditCollectionSheet(collection: .collectionFixture)
        .previewEnvironment()
}
#Preview {
    EditCollectionSheet(collection: .playlistFixture)
        .previewEnvironment()
}
#endif
