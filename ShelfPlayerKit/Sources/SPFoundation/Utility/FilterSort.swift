//
//  FilterSort.swift
//  
//
//  Created by Rasmus Krämer on 02.07.24.
//

import Foundation
import Defaults

// MARK: Items

public enum ItemDisplayType: String, Identifiable, Hashable, Codable, CaseIterable, Defaults.Serializable {
    case grid = "grid"
    case list = "list"
    
    public var id: Self {
        self
    }
}

public enum ItemFilter: String, Identifiable, Hashable, Codable, CaseIterable, Defaults.Serializable {
    case all = "sort.all"
    case progress = "sort.progress"
    case unfinished = "sort.unfinished"
    case finished = "sort.finished"
    
    public var id: Self {
        self
    }
}

// MARK: Audiobooks

public enum AudiobookSortOrder: String, Identifiable, Hashable, Codable, CaseIterable, Defaults.Serializable {
    case sortName
    case authorName
    case released
    case added
    case duration
    
    case lastPlayed
    case seriesName
    
    public var id: Self {
        self
    }
}

// MARK: Episodes

public enum EpisodeSortOrder: String, Identifiable, Hashable, Codable, CaseIterable, Defaults.Serializable {
    case name = "sort.name"
    case index = "sort.index"
    case released = "sort.released"
    case duration = "sort.duration"
    
    public var id: Self {
        self
    }
}
