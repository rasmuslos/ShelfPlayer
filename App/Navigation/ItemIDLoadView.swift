//
//  ItemIDLoadView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 05.10.23.
//

import SwiftUI
import ShelfPlayback

struct ItemIDLoadView: View {
    let name: String
    let type: ItemIdentifier.ItemType
    let libraryID: LibraryIdentifier

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
                let itemID: ItemIdentifier

                switch type {
                case .author:
                    itemID = try await ABSClient[libraryID.connectionID].authorID(from: libraryID, name: name)
                case .narrator:
                    itemID = Person.convertNarratorToID(name, libraryID: libraryID.libraryID, connectionID: libraryID.connectionID)
                case .channel:
                    itemID = Channel.convertNameToID(name, libraryID: libraryID.libraryID, connectionID: libraryID.connectionID)
                case .series:
                    itemID = try await ABSClient[libraryID.connectionID].seriesID(from: libraryID.libraryID, name: name)
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
