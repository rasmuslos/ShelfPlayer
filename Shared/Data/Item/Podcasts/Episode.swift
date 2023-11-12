//
//  Episode.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 07.10.23.
//

import Foundation
import SwiftSoup

class Episode: PlayableItem {
    let podcastId: String
    let podcastName: String
    
    let index: Int
    let duration: Double
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Item.Image?, genres: [String], addedAt: Date, released: String?, size: Int64, podcastId: String, podcastName: String, index: Int, duration: Double) {
        self.podcastId = podcastId
        self.podcastName = podcastName
        self.index = index
        self.duration = duration
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released, size: size)
    }
    
    // MARK: Getter
    
    lazy var releaseDate: Date? = {
        if let released = released, let milliseconds = Double(released) {
            return Date(timeIntervalSince1970: milliseconds / 1000)
        }
        
        return nil
    }()
    
    lazy var formattedReleaseDate: String? = {
        if let releaseDate = releaseDate {
            return String(releaseDate.get(.day)) + "." + String(releaseDate.get(.month)) + "." + String(releaseDate.get(.year))
        }
        
        return nil
    }()
    
    lazy var descriptionText: String? = {
        if let description = description, let document = try? SwiftSoup.parse(description) {
            return try? document.text()
        }
        
        return nil
    }()
    
    // MARK: playback
    
    override func getPlaybackData() async throws -> (PlayableItem.AudioTracks, PlayableItem.Chapters, Double, String?) {
        if offline == .downloaded {
            let track = AudioTrack(
                index: 0,
                offset: 0,
                duration: duration,
                codec: "",
                mimeType: "",
                contentUrl: DownloadManager.shared.getEpisodeUrl(episodeId: id).absoluteString)
            
            let chapters = await OfflineManager.shared.getChapters(itemId: id)
            let progress = await OfflineManager.shared.getProgress(item: self)
            let startTime: Double
            
            if progress?.progress ?? 0 >= 1 {
                startTime = 0
            } else {
                startTime = progress?.currentTime ?? 0
            }
            
            return ([track], chapters, startTime, nil)
        } else {
            return try await AudiobookshelfClient.shared.play(itemId: podcastId, episodeId: id)
        }
    }
    
    override func getPlaybackReporter(playbackSessionId: String?) throws -> PlaybackReporter {
        PlaybackReporter(itemId: podcastId, episodeId: id, playbackSessionId: playbackSessionId)
    }
    
    override func checkOfflineStatus() {
        Task.detached { [self] in
            offline = await OfflineManager.shared.getEpisodeOfflineStatus(episodeId: id)
        }
    }
}
