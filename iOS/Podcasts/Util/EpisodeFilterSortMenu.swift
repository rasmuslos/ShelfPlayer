//
//  EpisodeFilter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPBaseKit
import SPOfflineKit

struct EpisodeFilterSortMenu: View {
    let podcastId: String
    let enableSort: Bool
    
    @Binding var filter: Filter
    @Binding var sortOrder: SortOrder
    @Binding var ascending: Bool
    
    init(podcastId: String, filter: Binding<Filter>, sortOrder: Binding<SortOrder>, ascending: Binding<Bool>) {
        self.podcastId = podcastId
        self._filter = filter
        self._sortOrder = sortOrder
        self._ascending = ascending
        
        enableSort = true
    }
    init(podcastId: String, filter: Binding<Filter>) {
        self.podcastId = podcastId
        self._filter = filter
        
        self._sortOrder = .constant(.released)
        self._ascending = .constant(false)
        
        enableSort = false
    }
    
    var body: some View {
        Menu {
            ForEach(Filter.allCases, id: \.hashValue) { option in
                Button {
                    withAnimation {
                        filter = option
                        Self.setFilter(filter, podcastId: podcastId)
                    }
                } label: {
                    if option == filter {
                        Label(option.rawValue, systemImage: "checkmark")
                    } else {
                        Text(option.rawValue)
                    }
                }
            }
            
            if enableSort {
                Divider()
                
                ForEach(SortOrder.allCases, id: \.hashValue) { sortCase in
                    Button {
                        withAnimation {
                            sortOrder = sortCase
                            Self.setSortOrder(sortOrder, podcastId: podcastId)
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
                    ascending.toggle()
                    Self.setAscending(ascending, podcastId: podcastId)
                } label: {
                    if ascending {
                        Label("sort.ascending", systemImage: "checkmark")
                    } else {
                        Text("sort.ascending")
                    }
                }
            }
        } label: {
            if enableSort {
                Label("filterSort", systemImage: "arrow.up.arrow.down.circle.fill")
            } else {
                HStack {
                    Text(filter.rawValue)
                    Image(systemName: "chevron.down")
                }
                .font(.title3)
                .bold()
            }
        }
    }
}

// MARK: Filter

extension EpisodeFilterSortMenu {
    enum Filter: LocalizedStringKey, CaseIterable {
        case all = "sort.all"
        case progress = "sort.progress"
        case unfinished = "sort.unfinished"
        case finished = "sort.finished"
    }
    
    @MainActor
    static func filterEpisodes(_ episodes: [Episode], filter: Filter) -> [Episode] {
        episodes.filter {
            switch filter {
            case .all:
                return true
            case .progress, .unfinished, .finished:
                if let progress = OfflineManager.shared.getProgressEntity(item: $0) {
                    if filter == .unfinished {
                        return progress.progress < 1
                    }
                    if progress.progress < 1 && filter == .finished {
                        return false
                    }
                    if progress.progress >= 1 && filter == .progress {
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
    }
}

// MARK: Sort

extension EpisodeFilterSortMenu {
    enum SortOrder: LocalizedStringKey, CaseIterable {
        case name = "sort.name"
        case index = "sort.index"
        case released = "sort.released"
        case duration = "sort.duration"
    }
    
    static func sortEpisodes(_ episodes: [Episode], sortOrder: SortOrder, ascending: Bool) -> [Episode] {
        let episodes = episodes.sorted {
            switch sortOrder {
            case .name:
                $0.name < $1.name
            case .index:
                $0.index < $1.index
            case .released:
                $0.releaseDate ?? Date(timeIntervalSince1970: 0) < $1.releaseDate ?? Date(timeIntervalSince1970: 0)
            case .duration:
                $0.duration < $1.duration
            }
        }
        
        if ascending {
            return episodes
        } else {
            return episodes.reversed()
        }
    }
}

// MARK: Helper

extension EpisodeFilterSortMenu {
    @MainActor
    static func filterAndSortEpisodes(_ episodes: [Episode], filter: Filter, sortOrder: SortOrder, ascending: Bool) -> [Episode] {
        sortEpisodes(filterEpisodes(episodes, filter: filter), sortOrder: sortOrder, ascending: ascending)
    }
}

// MARK: Default

extension EpisodeFilterSortMenu {
    static func getFilter(podcastId: String) -> Filter {
        if let stored = UserDefaults.standard.string(forKey: "filter.\(podcastId)"), let parsed = Filter(rawValue: LocalizedStringKey(stored)) {
            return parsed
        }
        return .unfinished
    }
    
    static func getSortOrder(podcastId: String) -> SortOrder {
        if let stored = UserDefaults.standard.string(forKey: "sort.\(podcastId)"), let parsed = SortOrder(rawValue: LocalizedStringKey(stored)) {
            return parsed
        }
        return .released
    }
    static func getAscending(podcastId: String) -> Bool {
        UserDefaults.standard.bool(forKey: "ascending.\(podcastId)")
    }
    
    static func setFilter(_ filter: Filter, podcastId: String) {
        UserDefaults.standard.set(filter.rawValue.stringKey, forKey: "filter.\(podcastId)")
    }
    
    static func setSortOrder(_ sortOrder: SortOrder, podcastId: String) {
        UserDefaults.standard.set(sortOrder.rawValue.stringKey, forKey: "sort.\(podcastId)")
    }
    
    static func setAscending(_ ascending: Bool, podcastId: String) {
        UserDefaults.standard.set(ascending, forKey: "ascending.\(podcastId)")
    }
}

// MARK: Preview

#Preview {
    EpisodeFilterSortMenu(podcastId: "fixture", filter: .constant(.all))
}

#Preview {
    EpisodeFilterSortMenu(podcastId: "fixture", filter: .constant(.all), sortOrder: .constant(.released), ascending: .constant(false))
}
