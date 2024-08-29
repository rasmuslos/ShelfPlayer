//
//  EpisodeFilter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

struct EpisodeSortFilter: View {
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
            Label("filterSort", systemImage: "arrow.up.arrow.down.circle")
                .symbolVariant(filter == .all ? .none : .fill)
        }
    }
}

// MARK: Preview

#Preview {
    // these are here because swiftui does not like things in packages
    let _ = String(localized: "sort.unfinished")
    let _ = String(localized: "sort.progress")
    let _ = String(localized: "sort.index")
    let _ = String(localized: "sort.finished")
    let _ = String(localized: "sort.all")
    
    return EpisodeSortFilter(filter: .constant(.all), sortOrder: .constant(.released), ascending: .constant(false))
}
