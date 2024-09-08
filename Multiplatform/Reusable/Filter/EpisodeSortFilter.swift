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
    @Binding var filter: EpisodeFilter
    @Binding var sortOrder: EpisodeSortOrder
    @Binding var ascending: Bool
    
    var body: some View {
        Menu {
            ForEach(EpisodeFilter.allCases, id: \.hashValue) { option in
                Toggle(option.rawValue, isOn: .init(get: { filter == option }, set: {
                    if $0 {
                        filter = option
                    }
                }))
            }
            
            Divider()
            
            ForEach(EpisodeSortOrder.allCases, id: \.hashValue) { sortCase in
                Toggle(sortCase.rawValue, isOn: .init(get: { sortOrder == sortCase }, set: {
                    if $0 {
                        sortOrder = sortCase
                    }
                }))
            }
            
            Divider()
            
            Toggle("sort.ascending", systemImage: "arrowshape.up", isOn: $ascending)
        } label: {
            Label("filterSort", systemImage: "arrowshape.\(ascending ? "up" : "down")")
                .contentTransition(.symbolEffect)
        }
    }
}

private extension EpisodeFilter {
    var title: LocalizedStringKey {
        switch self {
            case .all:
                "filter.all"
            case .progress:
                "filter.inProgress"
            case .unfinished:
                "filter.unfinished"
            case .finished:
                "filter.finished"
        }
    }
}

private extension EpisodeSortOrder {
    var title: LocalizedStringKey {
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
}

#Preview {
    @Previewable @State var filter: EpisodeFilter = .all
    @Previewable @State var sortOrder: EpisodeSortOrder = .released
    @Previewable @State var ascending: Bool = false
    
    EpisodeSortFilter(filter: $filter, sortOrder: $sortOrder, ascending: $ascending)
}
