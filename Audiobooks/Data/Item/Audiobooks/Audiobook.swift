//
//  Audiobook.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

class Audiobook: PlayableItem {
    let narrator: String?
    let series: ReducedSeries
    
    let duration: Double
    
    let explicit: Bool
    let abridged: Bool
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Image?, genres: [String], addedAt: Date, released: String?, size: Int64, narrator: String?, series: ReducedSeries, duration: Double, explicit: Bool, abridged: Bool) {
        self.narrator = narrator
        self.series = series
        self.duration = duration
        self.explicit = explicit
        self.abridged = abridged
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released, size: size)
    }
    
    // MARK: playback
    
    override func getPlaybackData() async throws -> (PlayableItem.AudioTracks, PlayableItem.Chapters, Double, String?) {
        if offline == .downloaded {
            let tracks = try await OfflineManager.shared.getAudiobookTracksByAudiobookId(id).map {
                AudioTrack(
                    index: $0.index,
                    offset: $0.offset,
                    duration: $0.duration,
                    codec: "",
                    mimeType: "",
                    contentUrl: DownloadManager.shared.getAudiobookTrackUrl(trackId: $0.id).absoluteString)
            }
            let chapters = await OfflineManager.shared.getChapters(itemId: id)
            let progress = await OfflineManager.shared.getProgress(item: self)
            let startTime: Double
            
            if progress?.progress ?? 0 >= 1 {
                startTime = 0
            } else {
                startTime = progress?.currentTime ?? 0
            }
            
            return (tracks, chapters, startTime, nil)
        } else {
            return try await AudiobookshelfClient.shared.play(itemId: id, episodeId: nil)
        }
    }
    override func getPlaybackReporter(playbackSessionId: String?) throws -> PlaybackReporter {
        PlaybackReporter(itemId: id, episodeId: nil, playbackSessionId: playbackSessionId)
    }
    
    override func checkOfflineStatus() {
        Task.detached { [self] in
            offline = await OfflineManager.shared.getAudiobookOfflineStatus(audiobookId: id)
        }
    }
}

// MARK: Helper

extension Audiobook {
    struct ReducedSeries: Codable {
        let id: String?
        let name: String?
        let audiobookSeriesName: String?
    }
}
