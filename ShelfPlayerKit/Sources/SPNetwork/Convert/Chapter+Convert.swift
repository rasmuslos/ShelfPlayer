//
//  PlayableItem+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation
import SPFoundation

extension Chapter {
    init(payload: ChapterPayload) {
        self.init(id: payload.id, startOffset: payload.start, endOffset: payload.end, title: payload.title)
    }
}

extension PlayableItem.AudioTrack {
    init(track: AudiobookshelfAudioTrack) {
        self.init(
            index: track.index!,
            offset: track.startOffset,
            duration: track.duration,
            contentUrl: track.contentUrl)
    }
}
