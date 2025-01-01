//
//  AudioPlayer+Queue.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 04.09.24.
//

import Foundation
import Defaults
import SPFoundation
import SPNetwork
import SPPersistence
import SPExtension

public extension AudioPlayer {
    func advance(to index: Int) async throws {
        guard index < queue.count else {
            stop()
            return
        }
        
        queue.removeFirst(index)
        try await advance(finished: false)
    }
    
    func queue(_ item: PlayableItem) {
        if self.item == nil && queue.isEmpty {
            Task {
                // try await play(item)
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
        
        /*
        if let episodes = try? await ABSClient[episode.id.serverID].episodes(podcastId: episode.podcastId) {
            handleNextEpisodes(episodes, episode: episode)
            return
        }
        
        #if canImport(SPPersistenceExtended)
        if let episodes = try? OfflineManager.shared.episodes(podcastId: episode.podcastId) {
            handleNextEpisodes(episodes, episode: episode)
            return
        }
        #endif
         */
    }
    private func handleNextEpisodes(_ episodes: [Episode], episode: Episode) {
        /*
        let filter = Defaults[.episodesFilter(podcastId: episode.podcastId)]
        let sortOrder = Defaults[.episodesSortOrder(podcastId: episode.podcastId)]
        let ascending = Defaults[.episodesAscending(podcastId: episode.podcastId)]
        
        let episodes = Episode.filterSort(episodes: episodes, filter: filter, sortOrder: sortOrder, ascending: ascending)
        
        guard let index = episodes.firstIndex(of: episode) else {
            return
        }
        
        guard index < episodes.endIndex else {
            return
        }
        
        queue = Array(episodes[(index + 1)..<episodes.endIndex])
         */
    }
    
    func queueNextAudiobooksInSeries() async {
        guard let audiobook = item as? Audiobook else {
            return
        }
        
        /*
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
            
            if let audiobooks = try? await AudiobookshelfClient.shared.audiobooks(seriesID: seriesID, libraryID: audiobook.libraryID).0 {
                handleNextAudiobooksInSeries(audiobooks, audiobook: audiobook)
                break
            }
            
            // Looking for offline series is not supported (yet)
        }
         */
    }
    func handleNextAudiobooksInSeries(_ audiobooks: [Audiobook], audiobook: Audiobook) {
        /*
        let audiobooks = Audiobook.sort(audiobooks, sortOrder: .seriesName, ascending: true)
        
        guard let index = audiobooks.firstIndex(of: audiobook) else {
            return
        }
        
        guard index < audiobooks.endIndex else {
            return
        }
        
        queue = Array(audiobooks[(index + 1)..<audiobooks.endIndex])
         */
    }
}
