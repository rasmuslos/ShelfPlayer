//
//  PlayableItem+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation
import SPFoundation

extension Chapter {
    init(chapter: ChapterPayload) {
        self.init(
            id: chapter.id,
            startOffset: chapter.start,
            endOffset: chapter.end,
            title: chapter.title)
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
