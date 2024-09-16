//
//  AudiobooksSort.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import Defaults
import SPFoundation
import SPOffline

internal struct AudiobookSortFilter: View {
    @Binding var displayType: DisplayType
    @Binding var filter: Filter
    
    @Binding var sortOrder: SortOrder
    @Binding var ascending: Bool
    
    var didSelect: (() async -> Void)? = nil
    
    var body: some View {
        Menu {
            Section("section.display") {
                ControlGroup {
                    Button {
                        withAnimation {
                            displayType = .list
                        }
                    } label: {
                        Label("sort.list", systemImage: "list.bullet")
                    }
                    
                    Button {
                        withAnimation {
                            displayType = .grid
                        }
                    } label: {
                        Label("sort.grid", systemImage: "square.grid.2x2")
                    }
                }
            }
            
            Section("section.filter") {
                ForEach(Filter.allCases, id: \.hashValue) { option in
                    Toggle(option.rawValue, isOn: .init(get: { filter == option }, set: {
                        if $0 {
                            filter = option
                        }
                    }))
                }
            }
            
            Section("section.order") {
                ForEach(SortOrder.allCases, id: \.hashValue) { order in
                    Toggle(order.rawValue, isOn: .init(get: { sortOrder == order }, set: {
                        if $0 {
                            if let didSelect {
                                Task {
                                    await didSelect()
                                    sortOrder = order
                                }
                            } else {
                                sortOrder = order
                            }
                        }
                    }))
                }
                
                Divider()
                
                Toggle("sort.ascending", systemImage: "arrowshape.up", isOn: $ascending)
            }
        } label: {
            Label("filterSort", systemImage: "arrowshape.\(ascending ? "up" : "down")")
                .contentTransition(.symbolEffect)
        }
    }
}

// MARK: Filter sort function

extension AudiobookSortFilter {
    @MainActor
    static func filterSort(audiobooks: [Audiobook], filter: Filter, order: SortOrder, ascending: Bool) -> [Audiobook] {
        let audiobooks = audiobooks.filter { audiobook in
            if filter == .all {
                return true
            }
            
            let entity = OfflineManager.shared.progressEntity(item: audiobook)
            
            if filter == .finished && entity.progress >= 1 {
                return true
            } else if filter == .unfinished && entity.progress < 1 {
                return true
            }
            
            return false
        }
        
        return sort(audiobooks: audiobooks, order: order, ascending: ascending)
    }
    
    static func sort(audiobooks: [Audiobook], order: SortOrder, ascending: Bool) -> [Audiobook] {
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

// MARK: Types

internal extension AudiobookSortFilter {
    enum DisplayType: String, Defaults.Serializable {
        case grid = "grid"
        case list = "list"
    }
    
    enum Filter: LocalizedStringKey, CaseIterable, Codable, Defaults.Serializable {
        case all = "filter.all"
        case finished = "filter.finished"
        case unfinished = "filter.unfinished"
    }
    
    enum SortOrder: LocalizedStringKey, CaseIterable, Codable, Defaults.Serializable {
        case name = "sort.name"
        case series = "item.media.metadata.seriesName"
        case author = "sort.author"
        case released = "sort.released"
        case added = "sort.added"
        case duration = "sort.duration"
    }
}

extension AudiobookSortFilter.SortOrder {
    var apiValue: String {
        switch self {
            case .name:
                "media.metadata.title"
            case .series:
                "item.media.metadata.seriesName"
            case .author:
                "media.metadata.authorName"
            case .released:
                "media.metadata.publishedYear"
            case .added:
                "addedAt"
            case .duration:
                "media.duration"
        }
    }
}

#Preview {
    AudiobookSortFilter(displayType: .constant(.list), filter: .constant(.all), sortOrder: .constant(.added), ascending: .constant(true))
}
