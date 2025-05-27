//
//  SeriesMenu.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 31.10.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

struct ItemMenu: View {
    let items: [(id: ItemIdentifier?, name: String)]
    let type: ItemIdentifier.ItemType
    
    init(authors: [String]) {
        items = authors.map { (nil, $0) }
        type = .author
    }
    init(narrators: [String]) {
        items = narrators.map { (nil, $0) }
        type = .narrator
    }
    init(series: [Audiobook.SeriesFragment]) {
        items = series.map { ($0.id, $0.name) }
        type = .series
    }
    
    init(authors: [(id: ItemIdentifier, name: String)]) {
        items = authors
        type = .author
    }
    init(narrators: [(id: ItemIdentifier, name: String)]) {
        items = narrators
        type = .narrator
    }
    init(series: [(id: ItemIdentifier, name: String)]) {
        items = series
        type = .series
    }
    
    var body: some View {
        if items.count == 1, let item = items.first {
            link(item, type: type)
        } else if !items.isEmpty {
            Menu(type.viewLabel, systemImage: type.icon) {
                MenuInner(items: items, type: type)
            }
        }
    }
    
    struct MenuInner: View {
        let items: [(id: ItemIdentifier?, name: String)]
        let type: ItemIdentifier.ItemType
        
        init(items: [(id: ItemIdentifier?, name: String)], type: ItemIdentifier.ItemType) {
            self.items = items
            self.type = type
        }
        init(authors: [String]) {
            items = authors.map { (nil, $0) }
            type = .author
        }
        init(narrators: [String]) {
            items = narrators.map { (nil, $0) }
            type = .narrator
        }
        
        var body: some View {
            ForEach(items, id: \.name) {
                link($0, type: type)
            }
        }
    }
}

@ViewBuilder
private func link(_ item: (id: ItemIdentifier?, name: String), type: ItemIdentifier.ItemType) -> some View {    
    if let id = item.id {
        ItemLoadLink(itemID: id, footer: item.name)
    } else {
        ItemIDLoadLink(name: item.name, type: type, footer: item.name)
    }
}
