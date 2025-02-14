//
//  ItemSortOrderPicker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 10.02.25.
//

import SwiftUI
import SPFoundation

struct ItemSortOrderPicker<O: ItemSortOrder>: View {
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
    private func icon(for sortOrder: O) -> String {
        if self.sortOrder == sortOrder {
            ascending ? "chevron.down.2" : "chevron.up.2"
        } else {
            sortOrder.icon
        }
    }
    
    var body: some View {
        ForEach(Array(O.allCases)) {
            Toggle($0.label, systemImage: icon(for: $0), isOn: binding(for: $0))
                .tag($0)
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
            "sort.name"
        case .authorName:
            "sort.author"
        case .released:
            "sort.released"
        case .added:
            "sort.added"
        case .duration:
            "sort.duration"
        case .lastPlayed:
            "sort.lastPlayed"
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
        case .lastPlayed:
            "memories"
        }
    }
}

extension AuthorSortOrder: ItemSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .firstNameLastName:
            "sort.name.firstLast"
        case .lastNameFirstName:
            "sort.name.lastFirst"
        case .bookCount:
            "sort.bookCount"
        case .added:
            "sort.added"
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

extension SeriesSortOrder: ItemSortOrder {
    var label: LocalizedStringKey {
        switch self {
        case .sortName:
            "sort.name"
        case .bookCount:
            "sort.bookCount"
        case .added:
            "sort.added"
        case .duration:
            "sort.duration"
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
            "sort.name"
        case .author:
            "sort.author"
        case .episodeCount:
            "sort.episodeCount"
        case .addedAt:
            "sort.added"
        case .duration:
            "sort.duration"
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
            "sort.name"
        case .index:
            "sort.index"
        case .released:
            "sort.released"
        case .duration:
            "sort.duration"
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
