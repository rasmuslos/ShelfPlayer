//
//  EpisodeFilter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct EpisodeSortFilter: View {
    @Binding var filter: ItemFilter
    @Binding var sortOrder: EpisodeSortOrder
    @Binding var ascending: Bool
    
    var body: some View {
        Menu {
            ForEach(ItemFilter.allCases, id: \.hashValue) { option in
                Toggle(option.label, isOn: .init(get: { filter == option }, set: {
                    if $0 {
                        filter = option
                    }
                }))
            }
            
            Divider()
            
            ForEach(EpisodeSortOrder.allCases, id: \.hashValue) { sortCase in
                Toggle(sortCase.label, isOn: .init(get: { sortOrder == sortCase }, set: {
                    if $0 {
                        sortOrder = sortCase
                    }
                }))
            }
            
            Divider()
            
            Toggle("sort.ascending", systemImage: "arrowshape.up", isOn: $ascending)
        } label: {
            Label("filterSort", systemImage: "arrowshape.\(ascending ? "up" : "down").circle")
                .contentTransition(.symbolEffect(.replace.upUp))
        }
    }
}

#Preview {
    @Previewable @State var filter: ItemFilter = .all
    
    @Previewable @State var sortOrder: EpisodeSortOrder = .released
    @Previewable @State var ascending: Bool = false
    
    EpisodeSortFilter(filter: $filter, sortOrder: $sortOrder, ascending: $ascending)
}
