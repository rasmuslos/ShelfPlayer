//
//  EpisodeFilter.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI

struct EpisodeFilter: View {
    let podcastId: String
    @Binding var filter: Filter! {
        didSet {
            EpisodeFilter.setFilter(filter, podcastId: podcastId)
        }
    }
    
    var body: some View {
        Menu {
            ForEach(Filter.allCases, id: \.hashValue) { option in
                Button {
                    withAnimation {
                        filter = option
                    }
                } label: {
                    Text(option.rawValue)
                }
            }
        } label: {
            HStack {
                Text(filter.rawValue)
                Image(systemName: "chevron.down")
            }
            .font(.title3)
            .bold()
        }
        .foregroundStyle(.primary)
        
        Spacer()
    }
}

// MARK: Filter

extension EpisodeFilter {
    enum Filter: String, CaseIterable {
        case all = "All Episodes"
        case progress = "In Progress"
        case unfinished = "Unfinished"
        case finished = "Finished"
    }
    
    @MainActor
    static func filterEpisodes(_ episodes: [Episode], filter: Filter) -> [Episode] {
        episodes.filter {
            switch filter {
            case .all:
                return true
            case .progress, .unfinished, .finished:
                if let progress = OfflineManager.shared.getProgress(item: $0) {
                    if filter == .unfinished {
                        return progress.progress <= 0
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

// MARK: Sort

extension EpisodeFilter {
    enum SortOrder: String, CaseIterable {
        case name = "Name"
        case index = "Index"
        case released = "Released"
        case duration = "Duration"
    }
}

// MARK: Default

extension EpisodeFilter {
    static func getFilter(podcastId: String) -> Filter {
        if let stored = UserDefaults.standard.string(forKey: "filter.\(podcastId)"), let parsed = Filter(rawValue: stored) {
            return parsed
        }
        return .all
    }
    
    static func getSortOrder(podcastId: String) -> SortOrder {
        if let stored = UserDefaults.standard.string(forKey: "sort.\(podcastId)"), let parsed = SortOrder(rawValue: stored) {
            return parsed
        }
        return .released
    }
    static func getAscending(podcastId: String) -> Bool {
        UserDefaults.standard.bool(forKey: "ascending.\(podcastId)")
    }
    
    static func setFilter(_ filter: Filter, podcastId: String) {
        UserDefaults.standard.set(filter.rawValue, forKey: "filter.\(podcastId)")
    }
    
    static func setSortOrder(_ sortOrder: SortOrder, podcastId: String) {
        UserDefaults.standard.set(sortOrder.rawValue, forKey: "sort.\(podcastId)")
    }
    
    static func setAscending(_ ascending: Bool, podcastId: String) {
        UserDefaults.standard.set(ascending, forKey: "filter.\(podcastId)")
    }
}

#Preview {
    EpisodeFilter(podcastId: "fixture", filter: .constant(.all))
}
