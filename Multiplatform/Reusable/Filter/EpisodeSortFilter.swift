//
//  EpisodeFilter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import Defaults
import SPBase
import SPOffline

struct EpisodeSortFilter: View {
    @Binding var filter: Filter
    @Binding var sortOrder: SortOrder
    @Binding var ascending: Bool
    
    var body: some View {
        Menu {
            ForEach(Filter.allCases, id: \.hashValue) { option in
                Button {
                    withAnimation {
                        filter = option
                    }
                } label: {
                    if option == filter {
                        Label(option.rawValue, systemImage: "checkmark")
                    } else {
                        Text(option.rawValue)
                    }
                }
            }
            
            Divider()
            
            ForEach(SortOrder.allCases, id: \.hashValue) { sortCase in
                Button {
                    withAnimation {
                        sortOrder = sortCase
                    }
                } label: {
                    if sortCase == sortOrder {
                        Label(sortCase.rawValue, systemImage: "checkmark")
                    } else {
                        Text(sortCase.rawValue)
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
        } label: {
            Label("filterSort", systemImage: "arrow.up.arrow.down.circle")
                .symbolVariant(filter == .all ? .none : .fill)
        }
    }
}

extension EpisodeSortFilter {
    enum Filter: LocalizedStringKey, CaseIterable, Codable, Defaults.Serializable {
        case all = "sort.all"
        case progress = "sort.progress"
        case unfinished = "sort.unfinished"
        case finished = "sort.finished"
    }
    
    enum SortOrder: LocalizedStringKey, CaseIterable, Codable, Defaults.Serializable {
        case name = "sort.name"
        case index = "sort.index"
        case released = "sort.released"
        case duration = "sort.duration"
    }
}

extension Defaults.Keys {
    static func episodesFilter(podcastId: String) -> Defaults.Key<EpisodeSortFilter.Filter> {
        .init("episodesFilter-\(podcastId)", default: .unfinished)
    }
    
    static func episodesSort(podcastId: String) -> Defaults.Key<EpisodeSortFilter.SortOrder> {
        .init("episodesSort-\(podcastId)", default: .released)
    }
    static func episodesAscending(podcastId: String) -> Defaults.Key<Bool> {
        .init("episodesFilterAscending-\(podcastId)", default: false)
    }
}

// MARK: Sort

extension EpisodeSortFilter {
    @MainActor
    static func filterSort(episodes: [Episode], filter: Filter, sortOrder: SortOrder, ascending: Bool) -> [Episode] {
        var episodes = episodes.filter {
            switch filter {
                case .all:
                    return true
                case .progress, .unfinished, .finished:
                    let entity = OfflineManager.shared.requireProgressEntity(item: $0)
                    
                    if entity.progress > 0 {
                        if filter == .unfinished {
                            return entity.progress < 1
                        }
                        if entity.progress < 1 && filter == .finished {
                            return false
                        }
                        if entity.progress >= 1 && filter == .progress {
                            return false
                        }
                        
                        return true
                    } else {
                        if filter == .unfinished {
                            return true
                        } else {
                            return false
                        }
                    }
            }
        }
        
        episodes.sort {
            switch sortOrder {
                case .name:
                    return $0.name.localizedStandardCompare($1.name) == .orderedAscending
                case .index:
                    return $0.index < $1.index
                case .released:
                    guard let lhsReleaseDate = $0.releaseDate else { return false }
                    guard let rhsReleaseDate = $1.releaseDate else { return true }
                    
                    return lhsReleaseDate < rhsReleaseDate
                case .duration:
                    return $0.duration < $1.duration
            }
        }
        
        if ascending {
            return episodes
        } else {
            return episodes.reversed()
        }
    }
}

// MARK: Preview

#Preview {
    EpisodeSortFilter(filter: .constant(.all), sortOrder: .constant(.released), ascending: .constant(false))
}
