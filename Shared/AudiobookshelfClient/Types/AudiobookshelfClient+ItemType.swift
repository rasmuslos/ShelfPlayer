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
        let id: String
        let libraryId: String?
        
        let path: String?
        let mediaType: String?
        let type: String?
        
        let addedAt: Double?
        let updatedAt: Double?
        
        let size: Int64?
        
        let books: [AudiobookshelfItem]?
        let series: [AudiobookshelfItem]?
        let libraryItems: [AudiobookshelfItem]?
        
        let numEpisodes: Int?
        let recentEpisode: AudiobookshelfPodcastEpisode?
        
        let isLocal: Bool?
        
        let name: String?
        let description: String?
        let numBooks: Int?
        let imagePath: String?
        
        let media: AudiobookshelfItemMedia?
        
        let startTime: Double?
        let audioTracks: [AudiobookshelfAudioTrack]?
        let chapters: [AudiobookshelfChapter]?
        
        // MARK: Podcast episode
        
        struct AudiobookshelfPodcastEpisode: Codable {
            let id: String?
            let podcastId: String?
            let libraryItemId: String?
            
            let index: Int?
            let season: String?
            let episode: String?
            let title: String?
            let description: String?
            
            let pubDate: String?
            let publishedAt: Double?
            let addedAt: Double?
            let updatedAt: Double?
            
            let size: Int64?
            let duration: Double?
            
            let audioFile: PodcastAudioFile?
            let audioTrack: AudiobookshelfAudioTrack?
            
            let podcast: AudiobookshelfItemPodcast?
            let chapters: [AudiobookshelfChapter]?
            
            struct PodcastAudioFile: Codable {
                let duration: Double?
                let codec: String?
                let channelLayout: String?
                
                let metadata: PodcastMetadata?
            }
            struct PodcastMetadata: Codable {
                let size: Double?
            }
            struct AudiobookshelfItemPodcast: Codable {
                let id: String
                let libraryItemId: String
                let author: String?
                let coverPath: String?
                let metadata: AudiobookshelfItemMetadata
            }
        }
        
        // MARK: Media/Metadata
        
        struct AudiobookshelfItemMedia: Codable {
            let tags: [String]?
            let coverPath: String?
            
            let numTracks: Int?
            let numAudioFiles: Int?
            let numChapters: Int?
            let numMissingParts: Int?
            let numInvalidAudioFiles: Int?
            
            let duration: Double?
            
            let tracks: [AudiobookshelfAudioTrack]?
            let episodes: [AudiobookshelfPodcastEpisode]?
            
            let chapters: [AudiobookshelfChapter]?
            let metadata: AudiobookshelfItemMetadata
        }
        struct AudiobookshelfItemMetadata: Codable {
            let title: String?
            let titleIgnorePrefix: String?
            
            let subtitle: String?
            let description: String?
            
            let authorName: String?
            let author: String?
            let narratorName: String?
            let publisher: String?
            
            let seriesName: String?
            let series: AudiobookshelfItemSeries?
            
            let genres: [String]
            let publishedYear: String?
            let releaseDate: String?
            
            let isbn: String?
            let language: String?
            let explicit: Bool?
            let abridged: Bool?
            
            init(from decoder: Decoder) throws {
                let container: KeyedDecodingContainer<AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys> = try decoder.container(keyedBy: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.self)
                self.title = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.title)
                self.titleIgnorePrefix = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.titleIgnorePrefix)
                self.subtitle = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.subtitle)
                self.description = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.description)
                self.authorName = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.authorName)
                self.author = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.author)
                self.narratorName = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.narratorName)
                self.publisher = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.publisher)
                self.seriesName = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.seriesName)
                self.genres = try container.decode([String].self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.genres)
                self.publishedYear = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.publishedYear)
                self.releaseDate = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.releaseDate)
                self.isbn = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.isbn)
                self.language = try container.decodeIfPresent(String.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.language)
                self.explicit = try container.decodeIfPresent(Bool.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.explicit)
                self.abridged = try container.decodeIfPresent(Bool.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.abridged)
                
                // this is truly stupid... The field is either of type series or an empty array
                self.series = try? container.decodeIfPresent(AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemSeries.self, forKey: AudiobookshelfClient.AudiobookshelfItem.AudiobookshelfItemMetadata.CodingKeys.series)
            }
        }
        
        // MARK: Series
        
        struct AudiobookshelfItemSeries: Codable {
            let id: String?
            let name: String?
            let sequence: String?
        }
        
        // MARK: Audio track
        
        struct AudiobookshelfAudioTrack: Codable {
            let index: Int?
            let startOffset: Double
            let duration: Double
            let contentUrl: String
            let mimeType: String
            let codec: String
            
            let metadata: AudioTrackMetadata?
            
            struct AudioTrackMetadata: Codable {
                let ext: String?
            }
        }
        
        // MARK: Chapter
        
        struct AudiobookshelfChapter: Codable {
            let id: Int
            let start: Double
            let end: Double
            let title: String
        }
    }
}
