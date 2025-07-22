//
//  CollectionMembershipEditor.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 22.07.25.
//

import SwiftUI
import ShelfPlayback

struct CollectionMembershipEditorSheet: View {
    @Environment(Satellite.self) private var satellite
    
    let itemID: ItemIdentifier
    
    @State private var collectionLoader: LazyLoadHelper<ItemCollection, Void?>
    @State private var playlistLoader: LazyLoadHelper<ItemCollection, Void?>
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        
        _collectionLoader = .init(initialValue: .collections(.collection))
        _playlistLoader = .init(initialValue: .collections(.playlist))
    }
    
    @State private var createCollectionType: ItemCollection.CollectionType? = nil
    @State private var createCollectionName = ""
    
    @State private var isLoading = false
    @State private var notifyError = false
    @State private var notifySuccess = false
    
    @ViewBuilder
    private func createCollectionButton(type: ItemCollection.CollectionType) -> some View {
        Button {
            createCollectionType = type
        } label: {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(.gray.opacity(0.2))
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 68)
                    
                    if isLoading {
                        ProgressView()
                    } else {
                        Image(systemName: "plus")
                            .foregroundStyle(Color.accentColor)
                    }
                }
                
                Text(type.createLabel)
            }
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
    }
    @ViewBuilder
    private func rows(_ lazyLoader: LazyLoadHelper<ItemCollection, Void?>) -> some View {
        ForEach(lazyLoader.items) { collection in
            Button {
                addToCollection(collectionID: collection.id)
            } label: {
                ItemCompactRow(item: collection, context: .collectionLarge)
            }
            .buttonStyle(.plain)
            .disabled(collection.items.contains { $0.id == itemID })
            .listRowInsets(.init(top: 12, leading: 12, bottom: 12, trailing: 12))
        }
    }
    
    private var alertBinding: Binding<Bool> { .init() { createCollectionType != nil } set: {
        if !$0 {
            createCollectionType = nil
        }
    }}
    private var areCollectionsAvailable: Bool {
        itemID.type == .audiobook
    }
    
    var body: some View {
        NavigationStack {
            List {
                if areCollectionsAvailable {
                    Section(ItemCollection.CollectionType.collection.label) {
                        createCollectionButton(type: .collection)
                        rows(collectionLoader)
                    }
                }
                
                Section(ItemCollection.CollectionType.playlist.label) {
                    createCollectionButton(type: .playlist)
                    rows(playlistLoader)
                }
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("action.cancel") {
                        satellite.dismissSheet()
                    }
                    .disabled(isLoading)
                }
            }
        }
        .alert("item.collection.create", isPresented: alertBinding) {
            if let createCollectionType {
                TextField(createCollectionType.itemType.label, text: $createCollectionName)
                
                Button("action.cancel") {
                    self.createCollectionType = nil
                }
                .disabled(isLoading)
                
                Button("action.proceed") {
                    createCollection(type: createCollectionType)
                }
                .disabled(isLoading)
            }
        }
        .sensoryFeedback(.error, trigger: notifyError)
        .sensoryFeedback(.success, trigger: notifySuccess)
        .onAppear {
            let library = Library(id: itemID.libraryID, connectionID: itemID.connectionID, name: "_", type: areCollectionsAvailable ? .audiobooks : .podcasts, index: -1)
            
            collectionLoader.library = library
            playlistLoader.library = library
            
            if areCollectionsAvailable {
                collectionLoader.initialLoad()
            }
            playlistLoader.initialLoad()
        }
    }
    
    private nonisolated func addToCollection(collectionID: ItemIdentifier) {
        Task {
            await MainActor.withAnimation {
                isLoading = true
            }
            
            do {
                try await ABSClient[itemID.connectionID].bulkUpdateCollectionItems(collectionID, operation: .add, itemIDs: [itemID])
                
                await RFNotification[.collectionChanged].send(payload: collectionID)
                await PersistenceManager.shared.convenienceDownload.scheduleUpdate(itemID: collectionID)
                
                await MainActor.run {
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
            
            await MainActor.run {
                isLoading = false
                
                satellite.dismissSheet()
            }
        }
    }
    private nonisolated func createCollection(type: ItemCollection.CollectionType) {
        Task {
            await MainActor.withAnimation {
                guard !self.createCollectionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                    notifyError.toggle()
                    return
                }
                
                isLoading = true
            }
            
            let createCollectionName = await createCollectionName
            
            do {
                let collectionID = try await ABSClient[itemID.connectionID].createCollection(name: createCollectionName, type: type, libraryID: itemID.libraryID, itemIDs: [itemID])
                
                await collectionID.navigateIsolated()
                await RFNotification[.collectionChanged].send(payload: collectionID)
                
                await MainActor.run {
                    notifySuccess.toggle()
                }
            } catch {
                await MainActor.run {
                    notifyError.toggle()
                }
            }
            
            await MainActor.run {
                self.createCollectionType = nil
                self.createCollectionName = ""
                
                isLoading = false
                
                satellite.dismissSheet()
            }
        }
    }
}

extension ItemCollection.CollectionType {
    var createLabel: LocalizedStringKey {
        switch self {
            case .collection:
                "item.create.collection"
            case .playlist:
                "item.create.playlist"
        }
    }
}

#if DEBUG
#Preview {
    CollectionMembershipEditorSheet(itemID: .fixture)
        .previewEnvironment()
}
#endif
