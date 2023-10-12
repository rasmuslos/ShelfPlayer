//
//  DownloadManager+Track.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation

extension DownloadManager {
    func downloadTrack(track: PlayableItem.AudioTrack) -> URLSessionDownloadTask {
        urlSession.downloadTask(with: URLRequest(url: AudiobookshelfClient.shared.serverUrl
            .appending(path: track.contentUrl.removingPercentEncoding ?? "")
            .appending(queryItems: [
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token)
            ])))
    }
    
    func deleteAudiobookTrack(trackId: String) {
        try? FileManager.default.removeItem(at: getAudiobookTrackUrl(trackId: trackId))
    }
    
    func getAudiobookTrackUrl(trackId: String) -> URL {
        documentsURL.appending(path: "tracks").appending(path: "\(trackId).flac")
    }
    
    func deleteEpisode(episodeId: String) {
        try? FileManager.default.removeItem(at: getEpisodeUrl(episodeId: episodeId))
    }
    
    func getEpisodeUrl(episodeId: String) -> URL {
        documentsURL.appending(path: "tracks").appending(path: "\(episodeId).E.flac")
    }
}
