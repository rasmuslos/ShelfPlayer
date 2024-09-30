//
//  AudioPlayer+Queue.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 04.09.24.
//

import Foundation
import SPFoundation
import SPNetwork
import SPOffline
import SPOfflineExtended

public extension AudioPlayer {
    func queue(_ item: PlayableItem) {
        if self.item == nil && queue.isEmpty {
            Task {
                try await play(item)
            }
            
            return
        }
        
        queue.append(item)
    }
    
    /// A function that moves a queued item from the `from` index to the `to` position
    func move(from: Int, to: Int) {
        guard queue.count > from else {
            return
        }
        
        var copy = queue
        let to = min(to, queue.count)
        
        let track = copy.remove(at: from)
        
        if from > to {
            copy.insert(track, at: to)
        } else {
            copy.insert(track, at: to - 1)
        }
        
        queue = copy
    }
    
    func remove(at index: Int) {
        queue.remove(at: index)
    }
    
    func clear() {
        queue = []
    }
}

internal extension AudioPlayer {
    func queueNextEpisodes() async {
        guard let episode = item as? Episode else {
            return
        }
        
        if let episodes = try? await AudiobookshelfClient.shared.episodes(podcastId: episode.podcastId) {
            handleNextEpisodes(episodes, episode: episode)
            return
        }
        
        #if canImport(SPOfflineExtended)
        if let episodes = try? OfflineManager.shared.episodes(podcastId: episode.podcastId) {
            handleNextEpisodes(episodes, episode: episode)
            return
        }
        #endif
    }
    private func handleNextEpisodes(_ episodes: [Episode], episode: Episode) {
        let episodes = episodes.sorted { $0.index < $1.index }
        
        guard let index = episodes.firstIndex(of: episode) else {
            return
        }
        
        guard index < episodes.endIndex else {
            return
        }
        
        queue = Array(episodes[(index + 1)..<episodes.endIndex])
    }
    
    func queueNextAudiobooksInSeries() async {
        guard let audiobook = item as? Audiobook else {
            return
        }
        
        for series in audiobook.series {
            let seriesID: String
            
            if let id = series.id {
                seriesID = id
            } else {
                do {
                    seriesID = try await AudiobookshelfClient.shared.seriesID(name: series.name, libraryID: audiobook.libraryID)
                } catch {
                    continue
                }
            }
            
            if let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(seriesId: seriesID, libraryID: audiobook.libraryID, sortOrder: .series, ascending: true, limit: nil, page: nil).0 {
                handleNextAudiobooksInSeries(audiobooks, audiobook: audiobook)
                break
            }
            
            // Looking for offline series is not supported (yet)
        }
    }
    func handleNextAudiobooksInSeries(_ audiobooks: [Audiobook], audiobook: Audiobook) {
        guard let index = audiobooks.firstIndex(of: audiobook) else {
            return
        }
        
        guard index < audiobooks.endIndex else {
            return
        }
        
        queue = Array(audiobooks[(index + 1)..<audiobooks.endIndex])
    }
}
