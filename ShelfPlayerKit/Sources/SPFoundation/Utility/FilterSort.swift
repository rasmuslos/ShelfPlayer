//
//  FilterSort.swift
//  
//
//  Created by Rasmus Krämer on 02.07.24.
//

import Foundation
import Defaults

public enum ItemDisplayType: String, Identifiable, Hashable, Codable, Sendable, CaseIterable, Defaults.Serializable {
    case grid = "grid"
    case list = "list"
    
    public var id: String {
        rawValue
    }
}

public enum ItemFilter: String, Identifiable, Hashable, Codable, Sendable, CaseIterable, Defaults.Serializable {
    case all = "sort.all"
    case progress = "sort.progress"
    case unfinished = "sort.unfinished"
    case finished = "sort.finished"
    
    public var id: String {
        rawValue
    }
}

public enum AudiobookSortOrder: String, Identifiable, Hashable, Codable, Sendable, CaseIterable, Defaults.Serializable {
    case sortName
    case authorName
    case released
    case added
    case duration
    
    case lastPlayed
    
    public var id: String {
        rawValue
    }
}

public enum SeriesSortOrder: String, Identifiable, Hashable, Codable, Sendable, CaseIterable, Defaults.Serializable {
    case sortName
    case bookCount
    case added
    case duration
    
    public var id: String {
        rawValue
    }
}

public enum EpisodeSortOrder: String, Identifiable, Hashable, Codable, Sendable, CaseIterable, Defaults.Serializable {
    case name = "sort.name"
    case index = "sort.index"
    case released = "sort.released"
    case duration = "sort.duration"
    
    public var id: String {
        rawValue
    }
}

public enum PodcastSortOrder: String, Identifiable, Hashable, Codable, Sendable, CaseIterable, Defaults.Serializable {
    case name
    case author
    case episodeCount
    case addedAt
    case duration
    
    public var id: String {
        rawValue
    }
}
