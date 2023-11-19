//
//  PlayableItem.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 09.10.23.
//

import Foundation

@Observable
public class PlayableItem: Item {
    public let size: Int64
    public var offline: OfflineStatus
    
    private var token: NSObjectProtocol?
    
    init(id: String, libraryId: String, name: String, author: String?, description: String?, image: Image?, genres: [String], addedAt: Date, released: String?, size: Int64) {
        self.size = size
        offline = .none
        
        super.init(id: id, libraryId: libraryId, name: name, author: author, description: description, image: image, genres: genres, addedAt: addedAt, released: released)
        
        checkOfflineStatus()
        token = NotificationCenter.default.addObserver(forName: Self.downloadStatusUpdatedNotification, object: nil, queue: Self.operationQueue) { [weak self] notification in
            if notification.object as? String == self?.id {
                self?.checkOfflineStatus()
            }
        }
    }
    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    // MARK: Override
    
    func getPlaybackData() async throws -> (AudioTracks, Chapters, Double, String?) {
        throw PlaybackError.methodNotImplemented
    }
    func getPlaybackReporter(playbackSessionId: String?) throws -> PlaybackReporter {
        throw PlaybackError.methodNotImplemented
    }
    
    func checkOfflineStatus() {
    }
}

// MARK: Playback

extension PlayableItem {
    public func startPlayback() {
        if AudioPlayer.shared.item == self {
            AudioPlayer.shared.setPlaying(!AudioPlayer.shared.isPlaying())
            return
        }
        
        Task {
            if let (tracks, chapters, startTime, playbackSessionId) = try? await getPlaybackData(), let playbackReporter = try? getPlaybackReporter(playbackSessionId: playbackSessionId) {
                AudioPlayer.shared.startPlayback(item: self, tracks: tracks, chapters: chapters, startTime: startTime, playbackReporter: playbackReporter)
            }
        }
    }
}

// MARK: Offline

extension PlayableItem {
    static let operationQueue = OperationQueue()
    
    public enum OfflineStatus {
        case none
        case working
        case downloaded
    }
    
    public static let downloadStatusUpdatedNotification = NSNotification.Name("io.rfk.audiobooks.download.finished")
}

// MARK: Errors

extension PlayableItem {
    enum PlaybackError: Error {
        case methodNotImplemented
    }
}

// MARK: Types

extension PlayableItem {
    struct AudioTrack: Comparable {
        let index: Int
        
        let offset: Double
        let duration: Double
        
        let codec: String
        let mimeType: String
        let contentUrl: String
        
        // for some fucking reason i could not put this down in a extension
        static func < (lhs: PlayableItem.AudioTrack, rhs: PlayableItem.AudioTrack) -> Bool {
            lhs.index < rhs.index
        }
    }
    typealias AudioTracks = [AudioTrack]
    
    public struct Chapter: Identifiable, Comparable {
        public let id: Int
        public let start: Double
        public let end: Double
        public let title: String
        
        public static func < (lhs: PlayableItem.Chapter, rhs: PlayableItem.Chapter) -> Bool {
            lhs.start < rhs.start
        }
    }
    public typealias Chapters = [Chapter]
}
