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
    
    func deleteTrack(trackId: String) {
        try? FileManager.default.removeItem(at: getTrackUrl(trackId: trackId))
    }
    
    func getTrackUrl(trackId: String) -> URL {
        documentsURL.appending(path: "tracks").appending(path: "\(trackId).flac")
    }
}
