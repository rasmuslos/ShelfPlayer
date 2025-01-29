//
//  AuthorLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import RFNetwork
import ShelfPlayerKit

struct ItemIDLoadView: View {
    @Environment(\.library) private var library
    
    let name: String
    let type: ItemIdentifier.ItemType
    
    @State private var failed = false
    @State private var itemID: ItemIdentifier?
    
    var body: some View {
        if let itemID {
            ItemLoadView(itemID)
        } else if failed {
            ErrorView()
                .refreshable {
                    loadItem()
                }
        } else {
            LoadingView()
                .task {
                    loadItem()
                }
                .refreshable {
                    loadItem()
                }
        }
    }
    
    private nonisolated func loadItem() {
        Task {
            await MainActor.withAnimation {
                failed = false
            }
            
            do {
                guard let library = await library else { return }
                
                let itemID: ItemIdentifier
                
                switch type {
                case .series:
                    itemID = try await ABSClient[library.connectionID].seriesID(from: library.id, name: name)
                case .author:
                    itemID = try await ABSClient[library.connectionID].authorID(from: library.id, name: name)
                default:
                    throw LoadError.unsupporedItemType
                }
                
                await MainActor.withAnimation {
                    self.itemID = itemID
                }
            } catch {
                await MainActor.withAnimation {
                    failed = true
                }
            }
        }
    }
    
    private enum LoadError: Error {
        case unsupporedItemType
    }
}
