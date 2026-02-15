//
//  AuthorLoadView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayback

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
    
    private func loadItem() {
        Task {
            withAnimation {
                failed = false
            }
            
            do {
                guard let library = library else { return }
                
                let itemID: ItemIdentifier
                
                switch type {
                case .author:
                        itemID = try await ABSClient[library.id.connectionID].authorID(from: library.id, name: name)
                case .narrator:
                    itemID = Person.convertNarratorToID(name, libraryID: library.id.libraryID, connectionID: library.id.connectionID)
                case .series:
                    itemID = try await ABSClient[library.id.connectionID].seriesID(from: library.id.libraryID, name: name)
                default:
                    throw LoadError.unsupportedItemType
                }
                
                withAnimation {
                    self.itemID = itemID
                }
            } catch {
                withAnimation {
                    failed = true
                }
            }
        }
    }
    
    private enum LoadError: Error {
        case unsupportedItemType
    }
}

#Preview {
    Text("https://a.de/?a=vee&a=".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")
}
