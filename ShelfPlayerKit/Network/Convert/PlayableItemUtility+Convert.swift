//
//  PlayableItemUtility+Convert.swift
//  ShelfPlayerKit
//

import Foundation
import OSLog

private let logger = Logger(subsystem: "io.rfk.ShelfPlayerKit", category: "PlayableItem+Convert")

extension Chapter {
    init(payload: ChapterPayload) {
        self.init(id: payload.id, startOffset: payload.start, endOffset: payload.end, title: payload.title)
    }
}

extension PlayableItem.AudioFile {
    init?(track: AudiobookshelfAudioTrack) {
        guard let ino = track.ino else {
            return nil
        }

        var ext = track.metadata?.ext

        if ext?.starts(with: ".") == true {
            ext?.removeFirst()
        }

        self.init(ino: ino,
                  fileExtension: ext ?? "mp3",
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
