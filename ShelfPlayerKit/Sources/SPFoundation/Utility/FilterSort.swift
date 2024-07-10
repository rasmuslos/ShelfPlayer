//
//  FilterSort.swift
//  
//
//  Created by Rasmus Krämer on 02.07.24.
//

import Defaults

public enum EpisodeFilter: String, CaseIterable, Codable, Defaults.Serializable {
    case all = "sort.all"
    case progress = "sort.progress"
    case unfinished = "sort.unfinished"
    case finished = "sort.finished"
}

public enum EpisodeSortOrder: String, CaseIterable, Codable, Defaults.Serializable {
    case name = "sort.name"
    case index = "sort.index"
    case released = "sort.released"
    case duration = "sort.duration"
}
