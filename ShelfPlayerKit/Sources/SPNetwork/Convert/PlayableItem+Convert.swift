//
//  PlayableItem+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation
import SPFoundation

internal extension PlayableItem.AudioTrack {
    init(track: AudiobookshelfAudioTrack) {
        self.init(
            index: track.index!,
            offset: track.startOffset,
            duration: track.duration,
            codec: track.codec,
            mimeType: track.mimeType,
            contentUrl: track.contentUrl,
            fileExtension: track.metadata?.ext)
    }
}

internal extension PlayableItem.Chapter {
    init(chapter: AudiobookshelfChapter) {
        self.init(
            id: chapter.id,
            start: chapter.start,
            end: chapter.end,
            title: chapter.title)
    }
}
