//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

internal struct AudiobookshelfItem: Codable {
    let id: String
    let libraryId: String?
    
    let path: String?
    let mediaType: String?
    let type: String?
    
    let addedAt: Double?
    let updatedAt: Double?
    
    let size: Int64?
    
    // Both are have exactly the same use case, wtf?
    var books: [AudiobookshelfItem]?
    var items: [AudiobookshelfItem]?
    
    let series: [AudiobookshelfItem]?
    let libraryItems: [AudiobookshelfItem]?
    
    let numEpisodes: Int?
    var recentEpisode: AudiobookshelfPodcastEpisode?
    
    let isLocal: Bool?
    
    let name: String?
    let description: String?
    let numBooks: Int?
    let imagePath: String?
    
    let media: AudiobookshelfItemMedia?
    
    let startTime: Double?
    let audioTracks: [AudiobookshelfAudioTrack]?
    let chapters: [AudiobookshelfChapter]?
}

// MARK: Podcast episode

internal struct AudiobookshelfPodcastEpisode: Codable {
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
        
        let numAudioFiles: Int?
    }
}

// MARK: Media/Metadata

internal struct AudiobookshelfItemMedia: Codable {
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
    
    let audioFiles: [AudiobookshelfAudioFile]?
}

internal struct AudiobookshelfItemMetadata: Codable {
    let title: String?
    let titleIgnorePrefix: String?
    
    let subtitle: String?
    let description: String?
    
    let authorName: String?
    let author: String?
    let narratorName: String?
    let publisher: String?
    
    let seriesName: String?
    let series: [AudiobookshelfItemSeries]?
    
    let genres: [String]
    let publishedYear: String?
    let releaseDate: String?
    
    let isbn: String?
    let language: String?
    let explicit: Bool?
    let abridged: Bool?
    
    let type: String?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.titleIgnorePrefix = try container.decodeIfPresent(String.self, forKey: .titleIgnorePrefix)
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.narratorName = try container.decodeIfPresent(String.self, forKey: .narratorName)
        self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        self.seriesName = try container.decodeIfPresent(String.self, forKey: .seriesName)
        self.genres = try container.decode([String].self, forKey: .genres)
        self.publishedYear = try container.decodeIfPresent(String.self, forKey: .publishedYear)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        self.isbn = try container.decodeIfPresent(String.self, forKey: .isbn)
        self.language = try container.decodeIfPresent(String.self, forKey: .language)
        self.explicit = try container.decodeIfPresent(Bool.self, forKey: .explicit)
        self.abridged = try container.decodeIfPresent(Bool.self, forKey: .abridged)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        
        // this is truly stupid... The field is either of type series or an empty array
        if let seriesArray = try? container.decodeIfPresent([AudiobookshelfItemSeries].self, forKey: AudiobookshelfItemMetadata.CodingKeys.series) {
            self.series = seriesArray
        } else if let seriesDict = try? container.decodeIfPresent(AudiobookshelfItemSeries.self, forKey: AudiobookshelfItemMetadata.CodingKeys.series) {
            self.series = [seriesDict]
        } else {
            self.series = []
        }
    }
}

// MARK: Series

internal struct AudiobookshelfItemSeries: Codable {
    let id: String?
    let name: String?
    let sequence: String?
}

// MARK: Audio track

internal struct AudiobookshelfAudioTrack: Codable {
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

// MARK: Audio files

internal struct AudiobookshelfAudioFile: Codable {
    let index: Int
}

// MARK: Chapter

internal struct AudiobookshelfChapter: Codable {
    let id: Int
    let start: Double
    let end: Double
    let title: String
}
