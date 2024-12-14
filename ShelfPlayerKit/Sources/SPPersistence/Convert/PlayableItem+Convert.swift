//
//  File.swift
//
//
//  Created by Rasmus Krämer on 17.01.24.
//

import Foundation
import SPFoundation
import SPPersistence

internal extension PlayableItem.AudioTrack {
    init(_ track: OfflineTrack) {
        self.init(
            index: track.index,
            offset: track.offset,
            duration: track.duration,
            codec: "unknown",
            mimeType: "unknown",
            contentUrl: "unknown",
            fileExtension: track.fileExtension)
    }
}
