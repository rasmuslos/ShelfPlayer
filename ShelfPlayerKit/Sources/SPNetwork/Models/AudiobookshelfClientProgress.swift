//
//  AudiobookshelfClient+MediaProgress.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 17.09.23.
//

import Foundation

public struct MediaProgress: Codable {
    public let id: String
    public let libraryItemId: String
    public let episodeId: String?
    
    // This has to be optional because plappa is programmed by someone that apparently cannot program
    // I wasted an hour looking at ABS api changes to find this bug
    // What a fucking waste of time
    // BuT WHy caN'T It bE NulL?
    // Because the ABS api docs state that it is either the duration or `0` (https://api.audiobookshelf.org/#media-progress)
    public let duration: Double?
    public let progress: Double
    public let currentTime: Double
    
    public let hideFromContinueListening: Bool
    
    public let lastUpdate: Int64
    public let startedAt: Int64
    public let finishedAt: Int64?
}
