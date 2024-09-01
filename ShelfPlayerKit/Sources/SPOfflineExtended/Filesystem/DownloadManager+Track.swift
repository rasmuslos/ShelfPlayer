//
//  DownloadManager+Track.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation
import SPFoundation
import SPNetwork
import SPOffline

extension DownloadManager {
    func download(track: PlayableItem.AudioTrack) -> URLSessionDownloadTask {
        let url = AudiobookshelfClient.shared.serverUrl
            .appending(path: track.contentUrl.removingPercentEncoding ?? "")
            .appending(queryItems: [
                URLQueryItem(name: "token", value: AudiobookshelfClient.shared.token)
            ])
        var request = URLRequest(url: url)
        
        for header in AudiobookshelfClient.shared.customHTTPHeaders {
            request.addValue(header.value, forHTTPHeaderField: header.key)
        }
        
        return urlSession.downloadTask(with: request)
    }
    
    func remove(track: OfflineTrack) {
        try? FileManager.default.removeItem(at: trackURL(track: track))
    }
    
    func trackURL(track: OfflineTrack) -> URL {
        documentsURL.appending(path: "tracks").appending(path: "\(track.id).\(track.fileExtension)")
    }
}
