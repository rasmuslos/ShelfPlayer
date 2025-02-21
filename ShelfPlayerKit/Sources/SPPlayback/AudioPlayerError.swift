//
//  AudioPlayerError.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 21.02.25.
//

import Foundation

enum AudioPlayerError: Error {
    case offline
    case downloading
    
    case missingAudioTrack
    
    case loadFailed
}
