//
//  AudiobookshelfClient+Episodes.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import Foundation

// MARK: Latest episodes

extension AudiobookshelfClient {
    func getLatestEpisodes(libraryId: String) async throws -> [Episode] {
        let response = try await request(ClientRequest<EpisodesResponse>(path: "api/libraries/\(libraryId)/recent-episodes", method: "GET", query: [
            URLQueryItem(name: "page", value: "0"),
            URLQueryItem(name: "limit", value: "25"),
        ]))
        return response.episodes.map(Episode.convertFromAudiobookshelf)
    }
}

// MARK: Download data

extension AudiobookshelfClient {
    func getEpisodeDownloadData(podcastId: String, episodeId: String) async throws -> (PlayableItem.AudioTrack, PlayableItem.Chapters)? {
        let response = try await request(ClientRequest<AudiobookshelfItem>(path: "api/items/\(podcastId)", method: "GET", query: [
            URLQueryItem(name: "expanded", value: "1"),
        ]))
        
        if let episode = response.media?.episodes?.first(where: { $0.id == episodeId }) {
            let track = PlayableItem.convertAudioTrackFromAudiobookshelf(track: episode.audioTrack!)
            let chapters = episode.chapters!.map(PlayableItem.convertChapterFromAudiobookshelf)
            
            return (track, chapters)
        }
        
        return nil
    }
}

