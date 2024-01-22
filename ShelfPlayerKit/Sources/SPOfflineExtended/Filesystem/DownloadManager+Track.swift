//
//  DownloadManager+Track.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SPBase
import SPOffline

extension DownloadManager {
    func download(track: PlayableItem.AudioTrack) -> URLSessionDownloadTask {
        urlSession.downloadTask(with: URLRequest(url: AudiobookshelfClient.shared.serverUrl
            .appending(path: track.contentUrl.removingPercentEncoding ?? "")
            .appending(queryItems: [
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token)
            ])))
    }
    
    func delete(track: OfflineTrack) {
        try? FileManager.default.removeItem(at: getURL(track: track))
    }
    
    func getURL(track: OfflineTrack) -> URL {
        documentsURL.appending(path: "tracks").appending(path: "\(track.id).\(track.fileExtension)")
    }
}
