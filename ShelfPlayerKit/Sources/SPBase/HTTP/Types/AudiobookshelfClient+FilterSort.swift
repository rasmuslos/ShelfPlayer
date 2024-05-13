//
//  File.swift
//
//
//  Created by Rasmus Krämer on 13.05.24.
//

import SwiftUI
import Defaults

extension AudiobookshelfClient {
    public enum EpisodeFilter: LocalizedStringKey, CaseIterable, Codable, Defaults.Serializable {
        case all = "sort.all"
        case progress = "sort.progress"
        case unfinished = "sort.unfinished"
        case finished = "sort.finished"
    }
    
    public enum EpisodeSortOrder: LocalizedStringKey, CaseIterable, Codable, Defaults.Serializable {
        case name = "sort.name"
        case index = "sort.index"
        case released = "sort.released"
        case duration = "sort.duration"
    }
}
