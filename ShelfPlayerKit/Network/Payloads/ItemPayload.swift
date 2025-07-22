//
//  AudiobookshelfClient+Item.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation

struct ItemPayload: Codable {
    let id: String
    let libraryId: String?
    
    let path: String?
    let mediaType: String?
    let type: String?
    
    let addedAt: Double?
    let updatedAt: Double?
    let createdAt: Double?
    
    let size: Int64?
    
    // Both are have exactly the same use case, wtf?
    var books: [ItemPayload]?
    let items: [ItemPayload]?
    let playlistItems: [PlaylistItemPayload]?
    
    let series: [ItemPayload]?
    let libraryItems: [ItemPayload]?
    
    let numEpisodes: Int?
    let numEpisodesIncomplete: Int?
    
    var recentEpisode: EpisodePayload?
    
    let isLocal: Bool?
    
    let name: String?
    let description: String?
    let numBooks: Int?
    let imagePath: String?
    
    let media: MediaPayload?
    
    let startTime: Double?
    let audioTracks: [AudiobookshelfAudioTrack]?
    let chapters: [ChapterPayload]?
    
    let collapsedSeries: CollapsedSeriesPayload?
    
    let libraryFiles: [LibraryFile]?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(String.self, forKey: .id)
        self.libraryId = try container.decodeIfPresent(String.self, forKey: .libraryId)
        self.path = try container.decodeIfPresent(String.self, forKey: .path)
        self.mediaType = try container.decodeIfPresent(String.self, forKey: .mediaType)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        self.addedAt = try container.decodeIfPresent(Double.self, forKey: .addedAt)
        self.updatedAt = try container.decodeIfPresent(Double.self, forKey: .updatedAt)
        self.createdAt = try container.decodeIfPresent(Double.self, forKey: .createdAt)
        self.size = try container.decodeIfPresent(Int64.self, forKey: .size)
        self.books = try container.decodeIfPresent([ItemPayload].self, forKey: .books)
        self.series = try container.decodeIfPresent([ItemPayload].self, forKey: .series)
        self.libraryItems = try container.decodeIfPresent([ItemPayload].self, forKey: .libraryItems)
        self.numEpisodes = try container.decodeIfPresent(Int.self, forKey: .numEpisodes)
        self.numEpisodesIncomplete = try container.decodeIfPresent(Int.self, forKey: .numEpisodesIncomplete)
        self.recentEpisode = try container.decodeIfPresent(EpisodePayload.self, forKey: .recentEpisode)
        self.isLocal = try container.decodeIfPresent(Bool.self, forKey: .isLocal)
        self.name = try container.decodeIfPresent(String.self, forKey: .name)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.numBooks = try container.decodeIfPresent(Int.self, forKey: .numBooks)
        self.imagePath = try container.decodeIfPresent(String.self, forKey: .imagePath)
        self.media = try container.decodeIfPresent(MediaPayload.self, forKey: .media)
        self.startTime = try container.decodeIfPresent(Double.self, forKey: .startTime)
        self.audioTracks = try container.decodeIfPresent([AudiobookshelfAudioTrack].self, forKey: .audioTracks)
        self.chapters = try container.decodeIfPresent([ChapterPayload].self, forKey: .chapters)
        self.collapsedSeries = try container.decodeIfPresent(CollapsedSeriesPayload.self, forKey: .collapsedSeries)
        self.libraryFiles = try container.decodeIfPresent([LibraryFile].self, forKey: .libraryFiles)
        
        // This is bullshit:
        
        do {
            self.items = try container.decodeIfPresent([ItemPayload].self, forKey: .items)
            self.playlistItems = nil
        } catch {
            self.items = nil
            self.playlistItems = try container.decodeIfPresent([PlaylistItemPayload].self, forKey: .items)
        }
    }
}

struct LibraryFile: Codable {
    let ino: String
    let metadata: MetadataPayload
    
    let fileType: String
    let isSupplementary: Bool?
    
    struct MetadataPayload: Codable {
        public let ext: String
        public let filename: String
    }
}

struct EpisodePayload: Codable {
    let id: String?
    let libraryId: String?
    
    let podcastId: String?
    let libraryItemId: String?
    
    let index: Int?
    let season: String?
    let episode: String?
    let title: String?
    let description: String?
    
    let episodeType: String?
    
    let pubDate: String?
    let publishedAt: Double?
    let addedAt: Double?
    let updatedAt: Double?
    
    let size: Int64?
    let duration: Double?
    
    let audioFile: PodcastAudioFile?
    let audioTrack: AudiobookshelfAudioTrack?
    
    let podcast: AudiobookshelfItemPodcast?
    let libraryItem: AudiobookshelfItemPodcast?
    
    let chapters: [ChapterPayload]?
    
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
        let metadata: MetadataPayload
        
        let numAudioFiles: Int?
    }
}

struct PlaylistItemPayload: Codable {
    let episode: EpisodePayload?
    let libraryItem: ItemPayload?
}

struct CollapsedSeriesPayload: Codable {
    let id: String
    let name: String
    let libraryItemIds: [String]
}

struct MediaPayload: Codable {
    let tags: [String]?
    let coverPath: String?
    
    let numTracks: Int?
    let numAudioFiles: Int?
    let numChapters: Int?
    let numMissingParts: Int?
    let numInvalidAudioFiles: Int?
    
    let duration: Double?
    
    let tracks: [AudiobookshelfAudioTrack]?
    let episodes: [EpisodePayload]?
    
    let chapters: [ChapterPayload]?
    let metadata: MetadataPayload
    
    let audioFiles: [AudioFilePayload]?
}

struct MetadataPayload: Codable {
    // MARK: Shared
    
    let title: String?
    
    let description: String?
    let releaseDate: String?
    
    let genres: [String]
    
    let explicit: Bool?
    let language: String?
    
    // MARK: Book
    
    let subtitle: String?
    let publishedYear: String?
    let publisher: String?
    
    // undocumented
    let descriptionPlain: String?
    
    let isbn: String?
    let asin: String?
    // undocumented
    let abridged: Bool?
    
    // MARK: Book mini
    
    let authorName: String?
    let seriesName: String?
    let narratorName: String?
    
    // MARK: Book maxi
    
    let authors: [AudiobookshelfItemAuthor]?
    let narrators: [String]?
    let series: [AudiobookshelfItemSeries]?
    
    // MARK: Podcast
    
    let author: String?
    
    let feedUrl: String?
    let imageUrl: String?
    let itunesPageUrl: String?
    
    // let itunesId: Int?
    // let itunesArtistId: Int?
    
    let type: String?
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.title = try container.decodeIfPresent(String.self, forKey: .title)
        self.description = try container.decodeIfPresent(String.self, forKey: .description)
        self.releaseDate = try container.decodeIfPresent(String.self, forKey: .releaseDate)
        self.genres = try container.decode([String].self, forKey: .genres)
        self.explicit = try container.decodeIfPresent(Bool.self, forKey: .explicit)
        self.language = try container.decodeIfPresent(String.self, forKey: .language)
        self.subtitle = try container.decodeIfPresent(String.self, forKey: .subtitle)
        self.publishedYear = try container.decodeIfPresent(String.self, forKey: .publishedYear)
        self.publisher = try container.decodeIfPresent(String.self, forKey: .publisher)
        self.descriptionPlain = try container.decodeIfPresent(String.self, forKey: .descriptionPlain)
        self.isbn = try container.decodeIfPresent(String.self, forKey: .isbn)
        self.asin = try container.decodeIfPresent(String.self, forKey: .asin)
        self.abridged = try container.decodeIfPresent(Bool.self, forKey: .abridged)
        self.authorName = try container.decodeIfPresent(String.self, forKey: .authorName)
        self.seriesName = try container.decodeIfPresent(String.self, forKey: .seriesName)
        self.narratorName = try container.decodeIfPresent(String.self, forKey: .narratorName)
        self.authors = try container.decodeIfPresent([AudiobookshelfItemAuthor].self, forKey: .authors)
        self.narrators = try container.decodeIfPresent([String].self, forKey: .narrators)
        self.author = try container.decodeIfPresent(String.self, forKey: .author)
        self.feedUrl = try container.decodeIfPresent(String.self, forKey: .feedUrl)
        self.imageUrl = try container.decodeIfPresent(String.self, forKey: .imageUrl)
        self.itunesPageUrl = try container.decodeIfPresent(String.self, forKey: .itunesPageUrl)
        self.type = try container.decodeIfPresent(String.self, forKey: .type)
        
        // this is truly stupid... The field is either of type series or an empty array
        if let seriesArray = try? container.decodeIfPresent([AudiobookshelfItemSeries].self, forKey: .series) {
            self.series = seriesArray
        } else if let seriesDict = try? container.decodeIfPresent(AudiobookshelfItemSeries.self, forKey: .series) {
            self.series = [seriesDict]
        } else {
            self.series = []
        }
    }
}

struct AudiobookshelfItemSeries: Codable {
    let id: String?
    let name: String?
    let sequence: String?
}
struct AudiobookshelfItemAuthor: Codable {
    let id: String?
    let name: String?
}

struct AudiobookshelfAudioTrack: Codable {
    let index: Int?
    let ino: String?
    
    let startOffset: Double
    let duration: Double
    
    let contentUrl: String
    
    let mimeType: String
    let codec: String?
    
    let metadata: AudioTrackMetadata?
    
    struct AudioTrackMetadata: Codable {
        let ext: String
    }
}

struct AudioFilePayload: Codable {
    let index: Int?
}

internal struct ChapterPayload: Codable {
    let id: Int
    let start: Double
    let end: Double
    let title: String
}
