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

extension PlayableItem.AudioFile {
    init(track: AudiobookshelfAudioTrack) {
        var ext = track.metadata!.ext
        
        if ext.starts(with: ".") {
            ext.removeFirst()
        }
        
        self.init(ino: track.ino!,
                  fileExtension: ext,
                  offset: track.startOffset,
                  duration: track.duration)
    }
}
extension PlayableItem.AudioTrack {
    init(track: AudiobookshelfAudioTrack, base: URL) {
        self.init(offset: track.startOffset,
                  duration: track.duration,
                  resource: base.appending(path: track.contentUrl))
    }
}
