//
//  AudiobooksSort.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import Defaults
import SPBase
import SPOffline

struct AudiobookSortFilter: View {
    @Binding var display: DisplayType
    @Binding var filter: Filter
    
    @Binding var sort: SortOrder
    @Binding var ascending: Bool
    
    var body: some View {
        Menu {
            Section("section.display") {
                Button {
                    withAnimation {
                        display = .list
                    }
                } label: {
                    Label("sort.list", systemImage: "list.bullet")
                }
                
                Button {
                    withAnimation {
                        display = .grid
                    }
                } label: {
                    Label("sort.grid", systemImage: "square.grid.2x2")
                }
            }
            
            Section("section.filter") {
                ForEach(Filter.allCases, id: \.hashValue) { filter in
                    Button {
                        withAnimation {
                            self.filter = filter
                        }
                    } label: {
                        if self.filter == filter {
                            Label(filter.rawValue, systemImage: "checkmark")
                        } else {
                            Text(filter.rawValue)
                        }
                    }
                }
            }
            
            Section("section.order") {
                ForEach(SortOrder.allCases, id: \.hashValue) { order in
                    Button {
                        withAnimation {
                            sort = order
                        }
                    } label: {
                        if sort == order {
                            Label(order.rawValue, systemImage: "checkmark")
                        } else {
                            Text(order.rawValue)
                        }
                    }
                }
                
                Divider()
                
                Button {
                    withAnimation {
                        ascending.toggle()
                    }
                } label: {
                    if ascending {
                        Label("sort.ascending", systemImage: "checkmark")
                    } else {
                        Text("sort.ascending")
                    }
                }
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down.circle")
                .symbolVariant(filter == .all ? .none : .fill)
        }
    }
}

// MARK: Filter sort function

extension AudiobookSortFilter {
    @MainActor
    static func filterSort(audiobooks: [Audiobook], filter: Filter, order: SortOrder, ascending: Bool) -> [Audiobook] {
        // Filter
        var audiobooks = audiobooks.filter { audiobook in
            if filter == .all {
                return true
            }
            
            let entity = OfflineManager.shared.getProgressEntity(item: audiobook)
            
            if filter == .finished && entity?.progress ?? 0 >= 1 {
                return true
            } else if filter == .unfinished && entity?.progress ?? 0 < 1 {
                return true
            }
            
            return false
        }
        
        // Sort
        audiobooks.sort {
            switch order {
                case .name:
                    return $0.sortName.localizedStandardCompare($1.sortName) == .orderedDescending
                case .series:
                    guard let lhsSeries = $0.series.audiobookSeriesName else { return false }
                    guard let rhsSeries = $1.series.audiobookSeriesName else { return true }
                    
                    return lhsSeries.localizedStandardCompare(rhsSeries) == .orderedDescending
                case .author:
                    guard let lhsAuthor = $0.author else { return false }
                    guard let rhsAuthor = $1.author else { return true }
                    
                    return lhsAuthor.localizedStandardCompare(rhsAuthor) == .orderedDescending
                case .released:
                    guard let lhsReleased = $0.released else { return false }
                    guard let rhsReleased = $1.author else { return true }
                    
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

extension AudiobookSortFilter {
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

extension Defaults.Keys {
    static let audiobooksDisplay = Key<AudiobookSortFilter.DisplayType>("audiobooksDisplay", default: .list)
    static let audiobooksSortOrder = Key<AudiobookSortFilter.SortOrder>("audiobooksSortOrder", default: .added)
    
    static let audiobooksFilter = Key<AudiobookSortFilter.Filter>("audiobooksFilter", default: .all)
    static let audiobooksAscending = Key<Bool>("audiobooksFilterAscending", default: true)
}

#Preview {
    AudiobookSortFilter(display: .constant(.list), filter: .constant(.all), sort: .constant(.added), ascending: .constant(true))
}
