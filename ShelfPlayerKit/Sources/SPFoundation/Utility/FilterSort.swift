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
    case sortName = "media.metadata.title"
    case seriesName = "item.media.metadata.seriesName"
    case authorName = "media.metadata.authorName"
    case released = "media.metadata.publishedYear"
    case added = "addedAt"
    case duration = "media.duration"
    
    case lastPlayed = "internal.lastPlayed"
    
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
