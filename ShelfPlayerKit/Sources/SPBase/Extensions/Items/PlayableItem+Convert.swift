//
//  PlayableItem+Convert.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation

extension PlayableItem {
    static func convertAudioTrackFromAudiobookshelf(track: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfAudioTrack) -> AudioTrack {
        AudioTrack(
            index: track.index!,
            offset: track.startOffset,
            duration: track.duration,
            codec: track.codec,
            mimeType: track.mimeType,
            contentUrl: track.contentUrl,
            fileExtension: track.metadata!.ext!)
    }
    static func convertChapterFromAudiobookshelf(chapter: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfChapter) -> Chapter {
        Chapter(
            id: chapter.id,
            start: chapter.start,
            end: chapter.end,
            title: chapter.title)
    }
}
