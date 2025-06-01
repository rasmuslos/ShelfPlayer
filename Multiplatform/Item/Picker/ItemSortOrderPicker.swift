//
//  ItemSortOrderPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.02.25.
//

import SwiftUI
import ShelfPlayback

struct ItemSortOrderPicker<O: ItemSortOrder>: View {
    @Environment(\.library) private var library
    
    @Binding var sortOrder: O
    @Binding var ascending: Bool
    
    private func binding(for sortOrder: O) -> Binding<Bool> {
        .init() { self.sortOrder == sortOrder } set: {
            if $0 {
                self.sortOrder = sortOrder
            } else {
                ascending.toggle()
            }
        }
    }
    private func icon(for sortOrder: O) -> String? {
        if self.sortOrder == sortOrder {
            ascending ? "chevron.down" : "chevron.up"
        } else {
            // sortOrder.icon
            nil
        }
    }
    
    var body: some View {
        ForEach(Array(O.allCases)) { sortOrder in
            Group {
                if let icon = icon(for: sortOrder) {
                    Toggle(sortOrder.label, systemImage: icon, isOn: binding(for: sortOrder))
                } else {
                    Toggle(sortOrder.label, isOn: binding(for: sortOrder))
                }
            }
            .tag(sortOrder)
        }
    }
}

protocol ItemSortOrder: Equatable, Identifiable, Hashable, CaseIterable {
    var label: LocalizedStringKey { get }
    var icon: String { get }
}

extension AudiobookSortOrder: ItemSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .sortName:
            "item.sort.name"
        case .authorName:
            "item.sort.author"
        case .released:
            "item.sort.released"
        case .added:
            "item.sort.added"
        case .duration:
            "item.sort.duration"
        }
    }
    
    var icon: String {
        switch self {
        case .sortName:
            "text.quote"
        case .authorName:
            "person"
        case .released:
            "calendar"
        case .added:
            "plus.square"
        case .duration:
            "clock"
        }
    }
}

extension AuthorSortOrder: ItemSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .firstNameLastName:
            "item.sort.name.firstLast"
        case .lastNameFirstName:
            "item.sort.name.lastFirst"
        case .bookCount:
            "item.sort.bookCount"
        case .added:
            "item.sort.added"
        }
    }
    
    var icon: String {
        switch self {
        case .firstNameLastName:
            "text.insert"
        case .lastNameFirstName:
            "text.append"
        case .bookCount:
            "number"
        case .added:
            "document.badge.plus"
        }
    }
}
extension NarratorSortOrder: ItemSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .name:
            "item.sort.name"
        case .bookCount:
            "item.sort.bookCount"
        }
    }
    
    var icon: String {
        switch self {
        case .name:
            "text.quote"
        case .bookCount:
            "number"
        }
    }
}

extension SeriesSortOrder: ItemSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .sortName:
            "item.sort.name"
        case .bookCount:
            "item.sort.bookCount"
        case .added:
            "item.sort.added"
        case .duration:
            "item.sort.duration"
        }
    }
    
    var icon: String {
        switch self {
        case .sortName:
            "text.quote"
        case .bookCount:
            "number"
        case .added:
            "document.badge.plus"
        case .duration:
            "clock"
        }
    }
}

extension PodcastSortOrder: ItemSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .name:
            "item.sort.name"
        case .author:
            "item.sort.author"
        case .episodeCount:
            "item.sort.episodeCount"
        case .addedAt:
            "item.sort.added"
        case .duration:
            "item.sort.duration"
        }
    }
    
    var icon: String {
        switch self {
        case .name:
            "text.quote"
        case .author:
            "person"
        case .episodeCount:
            "number"
        case .addedAt:
            "document.badge.plus"
        case .duration:
            "clock"
        }
    }
}

extension EpisodeSortOrder: ItemSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .name:
            "item.sort.name"
        case .index:
            "item.sort.index"
        case .released:
            "item.sort.released"
        case .duration:
            "item.sort.duration"
        }
    }
    
    var icon: String {
        switch self {
        case .name:
            "text.quote"
        case .index:
            "list.number"
        case .released:
            "calendar"
        case .duration:
            "clock"
        }
    }
}

#Preview {
    ItemSortOrderPicker(sortOrder: .constant(AudiobookSortOrder.sortName), ascending: .constant(true))
    ItemSortOrderPicker(sortOrder: .constant(AuthorSortOrder.firstNameLastName), ascending: .constant(true))
    ItemSortOrderPicker(sortOrder: .constant(SeriesSortOrder.sortName), ascending: .constant(true))
}

#Preview {
    Menu(String("Options")) {
        ItemSortOrderPicker(sortOrder: .constant(AudiobookSortOrder.sortName), ascending: .constant(false))
        ItemSortOrderPicker(sortOrder: .constant(AuthorSortOrder.firstNameLastName), ascending: .constant(false))
        ItemSortOrderPicker(sortOrder: .constant(SeriesSortOrder.sortName), ascending: .constant(false))
    }
}
