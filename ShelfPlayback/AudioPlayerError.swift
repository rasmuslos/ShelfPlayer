//
//  AudioPlayerError.swift
//  ShelfPlayback
//
//  Created by Rasmus Krämer on 21.02.25.
//

import Foundation

enum AudioPlayerError: Error {
    case offline
    case downloading

    case invalidTime
    case missingAudioTrack

    case loadFailed
    case itemMissing

    case invalidItemType
}
