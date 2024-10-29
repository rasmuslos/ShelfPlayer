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
                SortOrders(options: [.name, .series, .author, .released, .added, .duration], sortOrder: $sortOrder, ascending: $ascending)
            }
        } label: {
            Label("filterSort", systemImage: "arrowshape.\(ascending ? "up" : "down").circle")
                .contentTransition(.symbolEffect(.replace.upUp))
        }
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

internal extension AudiobookSortFilter {
    static func filterSort(audiobooks: [Audiobook], filter: ItemFilter, order: AudiobookSortOrder, ascending: Bool) -> [Audiobook] {
        let audiobooks = audiobooks.filter { audiobook in
            if filter == .all {
                return true
            }
            
            let entity = OfflineManager.shared.progressEntity(item: audiobook)
            
            if filter == .finished && entity.isFinished {
                return true
            } else if filter == .unfinished && entity.progress < 1 {
                return true
            }
            
            return false
        }
        
        return sort(audiobooks: audiobooks, order: order, ascending: ascending)
    }
    
    static nonisolated func sort(audiobooks: [Audiobook], order: AudiobookSortOrder, ascending: Bool) -> [Audiobook] {
        let audiobooks = audiobooks.sorted {
            switch order {
            case .name:
                return $0.sortName.localizedStandardCompare($1.sortName) == .orderedAscending
            case .series:
                for (index, lhs) in $0.series.enumerated() {
                    if index > $1.series.count - 1 {
                        return true
                    }
                    
                    let rhs = $1.series[index]
                    
                    if lhs.name == rhs.name {
                        guard let lhsSequence = lhs.sequence else { return false }
                        guard let rhsSequence = rhs.sequence else { return true }
                        
                        return lhsSequence < rhsSequence
                    }
                    
                    return lhs.name.localizedStandardCompare(rhs.name) == .orderedAscending
                }
                
                return false
            case .author:
                guard let lhsAuthor = $0.author else { return false }
                guard let rhsAuthor = $1.author else { return true }
                
                return lhsAuthor.localizedStandardCompare(rhsAuthor) == .orderedAscending
            case .released:
                guard let lhsReleased = $0.released else { return false }
                guard let rhsReleased = $1.released else { return true }
                
                return lhsReleased < rhsReleased
            case .added:
                return $0.addedAt < $1.addedAt
            case .duration:
                return $0.duration < $1.duration
            case .lastPlayed:
                let lhs = OfflineManager.shared.progressEntity(item: $0)
                let rhs = OfflineManager.shared.progressEntity(item: $1)
                
                return lhs.lastUpdate < rhs.lastUpdate
            }
        }
        
        // Reverse if not ascending
        if ascending {
            return audiobooks
        } else {
            return audiobooks.reversed()
        }
    }
}

#Preview {
    AudiobookSortFilter(filter: .constant(.all), displayType: .constant(.list), sortOrder: .constant(.added), ascending: .constant(true))
}
