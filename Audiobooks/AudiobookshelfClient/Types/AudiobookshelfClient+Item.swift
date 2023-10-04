//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

// MARK: Item

extension AudiobookshelfClient {
    struct AudiobookshelfItem: Codable {
        var id: String
        var libraryId: String?
        
        var path: String?
        var mediaType: String?
        var type: String?
        
        var addedAt: Double?
        var updatedAt: Double?
        
        var size: Int64?
        
        var books: [AudiobookshelfItem]?
        
        var numEpisodes: Int?
        var recentEpisode: AudiobookshelfPodcastEpisode?
        
        var isLocal: Bool?
        
        var name: String?
        var description: String?
        var numBooks: Int?
        var imagePath: String?
        
        var media: AudiobookshelfItemMedia?
        
        // MARK: Podcast episode
        
        struct AudiobookshelfPodcastEpisode: Codable {
            var id: String?
            var libraryItemId: String?
            var index: Int?
            var season: String?
            var episode: String?
            var title: String?
            var description: String?
            
            var publishedAt: Double?
            var addedAt: Double?
            var updatedAt: Double?
            
            var size: Double?
            var duration: Double?
            
            var audioFile: PodcastAudioFile?
            var audioTrack: AudiobookshelfAudioTrack?
            
            struct PodcastAudioFile: Codable {
                var duration: Double?
                var codec: String?
                var channelLayout: String?
                
                var metadata: PodcastMetadata?
            }
            struct PodcastMetadata: Codable {
                var size: Double?
            }
        }
        
        // MARK: Media/Metadata
        
        struct AudiobookshelfItemMedia: Codable {
            var tags: [String]?
            var coverPath: String?
            
            var numTracks: Int?
            var numAudioFiles: Int?
            var numChapters: Int?
            var numMissingParts: Int?
            var numInvalidAudioFiles: Int?
            
            var duration: Double?
            
            var tracks: [AudiobookshelfAudioTrack]?
            var episodes: [AudiobookshelfPodcastEpisode]?
            var metadata: AudiobookshelfItemMetadata
        }
        struct AudiobookshelfItemMetadata: Codable {
            var title: String?
            var titleIgnorePrefix: String?
            
            var subtitle: String?
            var description: String?
            
            var authorName: String?
            var author: String?
            var narratorName: String?
            var publisher: String?
            var seriesName: String?
            
            var genres: [String]
            var publishedYear: String?
            
            var isbn: String?
            var language: String?
            var explicit: Bool?
            var abridged: Bool?
        }
        
        // MARK: Audio track
        
        struct AudiobookshelfAudioTrack: Codable {
            let index: Int?
            let startOffset: Double
            let duration: Double
            let contentUrl: String
            
            let metadata: AudioTrackMetadata?
            
            struct AudioTrackMetadata: Codable {
                let ext: String?
            }
        }
    }
}
