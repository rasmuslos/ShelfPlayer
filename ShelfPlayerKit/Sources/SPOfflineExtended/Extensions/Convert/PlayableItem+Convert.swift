//
//  File.swift
//
//
//  Created by Rasmus Krämer on 17.01.24.
//

import Foundation
import SPFoundation
import SPOffline

extension PlayableItem {
    static func convertTrackFromOffline(_ track: OfflineTrack) -> AudioTrack {
        AudioTrack(
            index: track.index,
            offset: track.offset,
            duration: track.duration,
            codec: "unknown",
            mimeType: "unknown",
            contentUrl: "unknown",
            fileExtension: track.fileExtension)
    }
}
