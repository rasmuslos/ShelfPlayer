//
//  ItemMenu.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.10.24.
//

import Foundation
import SwiftUI
import ShelfPlayback

struct ItemMenu: View {
    let items: [(id: ItemIdentifier?, name: String)]
    let type: ItemIdentifier.ItemType
    let libraryID: LibraryIdentifier

    init(authors: [String], libraryID: LibraryIdentifier) {
        items = authors.map { (nil, $0) }
        type = .author
        self.libraryID = libraryID
    }
    init(narrators: [String], libraryID: LibraryIdentifier) {
        items = narrators.map { (nil, $0) }
        type = .narrator
        self.libraryID = libraryID
    }
    init(series: [Audiobook.SeriesFragment], libraryID: LibraryIdentifier) {
        items = series.map { ($0.id, $0.name) }
        type = .series
        self.libraryID = libraryID
    }

    init(authors: [(id: ItemIdentifier, name: String)], libraryID: LibraryIdentifier) {
        items = authors
        type = .author
        self.libraryID = libraryID
    }
    init(narrators: [(id: ItemIdentifier, name: String)], libraryID: LibraryIdentifier) {
        items = narrators
        type = .narrator
        self.libraryID = libraryID
    }
    init(series: [(id: ItemIdentifier, name: String)], libraryID: LibraryIdentifier) {
        items = series
        type = .series
        self.libraryID = libraryID
    }

    var body: some View {
        if items.count == 1, let item = items.first {
            link(item, type: type, libraryID: libraryID)
        } else if !items.isEmpty {
            Menu(type.viewLabel, systemImage: type.icon) {
                MenuInner(items: items, type: type, libraryID: libraryID)
            }
        }
    }

    struct MenuInner: View {
        let items: [(id: ItemIdentifier?, name: String)]
        let type: ItemIdentifier.ItemType
        let libraryID: LibraryIdentifier

        init(items: [(id: ItemIdentifier?, name: String)], type: ItemIdentifier.ItemType, libraryID: LibraryIdentifier) {
            self.items = items
            self.type = type
            self.libraryID = libraryID
        }
        init(authors: [String], libraryID: LibraryIdentifier) {
            items = authors.map { (nil, $0) }
            type = .author
            self.libraryID = libraryID
        }
        init(narrators: [String], libraryID: LibraryIdentifier) {
            items = narrators.map { (nil, $0) }
            type = .narrator
            self.libraryID = libraryID
        }

        var body: some View {
            ForEach(items, id: \.name) {
                link($0, type: type, libraryID: libraryID)
            }
        }
    }
}

@ViewBuilder
private func link(_ item: (id: ItemIdentifier?, name: String), type: ItemIdentifier.ItemType, libraryID: LibraryIdentifier) -> some View {
    if let id = item.id {
        ItemLoadLink(itemID: id, footer: item.name)
    } else {
        ItemIDLoadLink(name: item.name, type: type, libraryID: libraryID, footer: item.name)
    }
}
