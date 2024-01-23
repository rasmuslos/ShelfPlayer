//
//  AudiobooksSort.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import SPBase
import SPOffline

struct AudiobooksFilterSort: View {
    @Binding var display: DisplayType {
        didSet {
            if !disableDefaults {
                UserDefaults.standard.set(display.rawValue, forKey: "audiobooks.display")
            }
        }
    }
    @Binding var filter: Filter
    
    @Binding var sort: SortOrder
    @Binding var ascending: Bool
    
    var disableDefaults = false
    
    var body: some View {
        Menu {
            Section("section.display") {
                Button {
                    display = .list
                } label: {
                    Label("sort.list", systemImage: "list.bullet")
                }
                Button {
                    display = .grid
                } label: {
                    Label("sort.grid", systemImage: "square.grid.2x2")
                }
            }
            
            Section("section.filter") {
                ForEach(Filter.allCases, id: \.hashValue) { filter in
                    Button {
                        self.filter = filter
                        
                        if !disableDefaults {
                            UserDefaults.standard.set(sort.rawValue.stringKey, forKey: "audiobooks.filter")
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
                        sort = order
                        
                        if !disableDefaults {
                            UserDefaults.standard.set(sort.rawValue.stringKey, forKey: "audiobooks.sort")
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
                    ascending.toggle()
                    
                    if !disableDefaults {
                        UserDefaults.standard.set(ascending, forKey: "audiobooks.sort.ascending")
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
            Image(systemName: "arrow.up.arrow.down.circle.fill")
        }
    }
}

// MARK: Types

extension AudiobooksFilterSort {
    enum DisplayType: String {
        case grid = "grid"
        case list = "list"
    }
    
    enum Filter: LocalizedStringKey, CaseIterable {
        case all = "filter.all"
        case finished = "filter.finished"
        case unfinished = "filter.unfinished"
    }
    
    enum SortOrder: LocalizedStringKey, CaseIterable {
        case name = "sort.name"
        case series = "item.media.metadata.seriesName"
        case author = "sort.author"
        case released = "sort.released"
        case added = "sort.added"
        case duration = "sort.duration"
    }
}

// MARK: Persistence

extension AudiobooksFilterSort {
    static func getDisplayType() -> DisplayType {
        if let stored = UserDefaults.standard.string(forKey: "audiobooks.display"), let parsed = DisplayType(rawValue: stored) {
            return parsed
        }
        return .grid
    }
    static func getFilter() -> Filter {
        if let stored = UserDefaults.standard.string(forKey: "audiobooks.filter"), let parsed = Filter(rawValue: LocalizedStringKey(stored)) {
            return parsed
        }
        
        return .all
    }
    
    static func getSortOrder() -> SortOrder {
        if let stored = UserDefaults.standard.string(forKey: "audiobooks.sort"), let parsed = SortOrder(rawValue: LocalizedStringKey(stored)) {
            return parsed
        }
        return .name
    }
    static func getAscending() -> Bool {
        UserDefaults.standard.bool(forKey: "audiobooks.sort.ascending")
    }
}

// MARK: Sort

extension AudiobooksFilterSort {
    @MainActor
    static func filterSort(audiobooks: [Audiobook], filter: Filter, order: SortOrder, ascending: Bool) -> [Audiobook] {
        let filterSorted = audiobooks.sorted {
            switch order {
            case .name:
                return $0.sortName < $1.sortName
            case .series:
                return $0.series.audiobookSeriesName ?? $0.series.name ?? "" < $1.series.audiobookSeriesName ?? $1.series.name ?? ""
            case .author:
                if $0.author == nil {
                    return false
                }
                if $1.author == nil {
                    return true
                }
                
                return $0.author! < $1.author!
            case .released:
                if $0.released == nil {
                    return false
                }
                if $1.released == nil {
                    return true
                }
                
                return $0.released! < $1.released!
            case .added:
                return $0.addedAt < $1.addedAt
            case .duration:
                return $0.duration < $1.duration
            }
        }.filter { audiobook in
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
        
        if ascending {
            return filterSorted
        } else {
            return filterSorted.reversed()
        }
    }
}

#Preview {
    AudiobooksFilterSort(display: .constant(.grid), filter: .constant(.all), sort: .constant(.name), ascending: .constant(false))
}
