//
//  AudiobooksSort.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayerKit

internal struct AudiobookSortFilter: View {
    @Binding var filter: ItemFilter
    @Binding var displayType: ItemDisplayType
    
    @Binding var sortOrder: AudiobookSortOrder
    @Binding var ascending: Bool
    
    var didSelect: (() async -> Void)? = nil
    
    var body: some View {
        Menu {
            Section("section.displayType") {
                ControlGroup {
                    ForEach(ItemDisplayType.allCases) { displayType in
                        Button {
                            withAnimation {
                                self.displayType = displayType
                            }
                        } label: {
                            Label(displayType.label, systemImage: displayType.icon)
                        }
                    }
                }
            }
            
            Section("section.filter") {
                ForEach(ItemFilter.allCases, id: \.hashValue) { filter in
                    Toggle(filter.label, isOn: .init(get: { self.filter == filter }, set: {
                        if $0 {
                            withAnimation {
                                self.filter = filter
                            }
                        }
                    }))
                }
            }
            
            Section("section.sortOrder") {
                SortOrders(options: [.sortName, .authorName, .released, .added, .duration], sortOrder: $sortOrder, ascending: $ascending)
            }
        } label: {
            Label("filterSort", systemImage: "arrowshape.\(ascending ? "up" : "down").circle")
                .contentTransition(.symbolEffect(.replace.upUp))
        }
        .menuActionDismissBehavior(.disabled)
        .onChange(of: sortOrder) {
            Task {
                await didSelect?()
            }
        }
    }
}

internal extension AudiobookSortFilter {
    struct SortOrders: View {
        let options: [AudiobookSortOrder]
        
        @Binding var sortOrder: AudiobookSortOrder
        @Binding var ascending: Bool
        
        var body: some View {
            ForEach(options) { sortOrder in
                Toggle(sortOrder.label, isOn: .init(get: { self.sortOrder == sortOrder }, set: {
                    if $0 {
                        self.sortOrder = sortOrder
                    }
                }))
            }
            
            Divider()
            
            Toggle("sort.ascending", systemImage: "arrowshape.up", isOn: $ascending)
        }
    }
}

#Preview {
    AudiobookSortFilter(filter: .constant(.all), displayType: .constant(.list), sortOrder: .constant(.added), ascending: .constant(true))
}
