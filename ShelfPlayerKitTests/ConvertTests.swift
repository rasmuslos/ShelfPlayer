//
//  ConvertTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct ConvertTests {
    // MARK: - Helpers

    private func decode(_ json: String) throws -> ItemPayload {
        try JSONDecoder().decode(ItemPayload.self, from: json.data(using: .utf8)!)
    }

    // MARK: - Audiobook+Convert

    private static let audiobookJSON = """
    {
      "id": "ab1",
      "libraryId": "lib1",
      "addedAt": 1700000000000,
      "size": 5000,
      "media": {
        "duration": 7200,
        "numAudioFiles": 1,
        "metadata": {
          "title": "The Title",
          "subtitle": "Subtitle",
          "authorName": "Author A, Author B",
          "narratorName": "Narrator A, Narrator B",
          "publishedYear": "2020",
          "description": "  Some description  ",
          "genres": ["Genre1", "Genre2"],
          "explicit": true,
          "abridged": true,
          "series": [
            {"id": "s1", "name": "Saga", "sequence": "1.5"}
          ]
        }
      }
    }
    """

    @Test func audiobookConvertSuccess() throws {
        let payload = try decode(Self.audiobookJSON)
        let book = Audiobook(payload: payload, libraryID: "lib1", connectionID: "conn1")
        #expect(book != nil)
        #expect(book?.id.primaryID == "ab1")
        #expect(book?.id.libraryID == "lib1")
        #expect(book?.id.connectionID == "conn1")
        #expect(book?.id.type == .audiobook)
        #expect(book?.name == "The Title")
        #expect(book?.subtitle == "Subtitle")
        #expect(book?.authors == ["Author A", "Author B"])
        #expect(book?.narrators == ["Narrator A", "Narrator B"])
        #expect(book?.duration == 7200)
        #expect(book?.size == 5000)
        #expect(book?.released == "2020")
        #expect(book?.explicit == true)
        #expect(book?.abridged == true)
        #expect(book?.genres == ["Genre1", "Genre2"])
        #expect(book?.description == "Some description")
    }

    @Test func audiobookConvertSeriesFromArray() throws {
        let payload = try decode(Self.audiobookJSON)
        let book = Audiobook(payload: payload, libraryID: "lib1", connectionID: "conn1")
        #expect(book?.series.count == 1)
        #expect(book?.series.first?.name == "Saga")
        #expect(book?.series.first?.sequence == 1.5)
        #expect(book?.series.first?.id?.primaryID == "s1")
    }

    @Test func audiobookConvertNoMediaReturnsNil() throws {
        let payload = try decode("""
        {"id": "x", "libraryId": "l"}
        """)
        let book = Audiobook(payload: payload, libraryID: "l", connectionID: "c")
        #expect(book == nil)
    }

    @Test func audiobookConvertZeroAudioFilesReturnsNil() throws {
        let payload = try decode("""
        {
          "id": "x",
          "libraryId": "l",
          "media": {
            "numAudioFiles": 0,
            "metadata": {"title": "T", "genres": []}
          }
        }
        """)
        let book = Audiobook(payload: payload, libraryID: "l", connectionID: "c")
        #expect(book == nil)
    }

    @Test func audiobookConvertSeriesNameParsed() throws {
        let payload = try decode("""
        {
          "id": "ab1",
          "libraryId": "lib1",
          "media": {
            "metadata": {
              "title": "T",
              "seriesName": "Foo #1, Bar",
              "genres": []
            }
          }
        }
        """)
        let book = Audiobook(payload: payload, libraryID: "lib1", connectionID: "c")
        #expect(book?.series.count == 2)
        let names = (book?.series.map(\.name)) ?? []
        #expect(names.contains("Foo"))
        #expect(names.contains("Bar"))
    }

    @Test func audiobookConvertEmptyAuthorsAndNarrators() throws {
        let payload = try decode("""
        {
          "id": "ab1",
          "libraryId": "lib1",
          "media": {
            "metadata": {"title": "T", "genres": []}
          }
        }
        """)
        let book = Audiobook(payload: payload, libraryID: "lib1", connectionID: "c")
        #expect(book?.authors.isEmpty == true)
        #expect(book?.narrators.isEmpty == true)
        #expect(book?.explicit == false)
        #expect(book?.abridged == false)
    }

    // MARK: - Series+Convert

    @Test func seriesConvert() throws {
        let payload = try decode("""
        {
          "id": "s1",
          "name": "Saga",
          "description": "About",
          "addedAt": 1700000000000,
          "books": [
            {
              "id": "b1",
              "libraryId": "lib1",
              "media": {
                "numAudioFiles": 1,
                "metadata": {"title": "Book One", "genres": []}
              }
            }
          ]
        }
        """)
        let series = Series(payload: payload, libraryID: "lib1", connectionID: "conn1")
        #expect(series.id.primaryID == "s1")
        #expect(series.id.type == .series)
        #expect(series.name == "Saga")
        #expect(series.description == "About")
        #expect(series.audiobooks.count == 1)
        #expect(series.audiobooks[0].id.primaryID == "b1")
    }

    @Test func seriesConvertNoBooks() throws {
        let payload = try decode("""
        {"id":"s1","name":"Saga"}
        """)
        let series = Series(payload: payload, libraryID: "lib1", connectionID: "c")
        #expect(series.audiobooks.isEmpty)
    }

    @Test func seriesFragmentParseSimple() {
        let result = Audiobook.SeriesFragment.parse(seriesName: "Saga #1")
        #expect(result.count == 1)
        #expect(result[0].name == "Saga")
        #expect(result[0].sequence == 1.0)
    }

    @Test func seriesFragmentParseMultiple() {
        let result = Audiobook.SeriesFragment.parse(seriesName: "Saga #1, Other")
        #expect(result.count == 2)
        #expect(result[0].name == "Saga")
        #expect(result[1].name == "Other")
        #expect(result[1].sequence == nil)
    }

    @Test func seriesFragmentParseNonNumericSequence() {
        let result = Audiobook.SeriesFragment.parse(seriesName: "Saga #book-one")
        #expect(result.count == 1)
        #expect(result[0].name == "Saga #book-one")
        #expect(result[0].sequence == nil)
    }

    @Test func seriesFragmentParseNoSequence() {
        let result = Audiobook.SeriesFragment.parse(seriesName: "Lonely")
        #expect(result.count == 1)
        #expect(result[0].name == "Lonely")
        #expect(result[0].sequence == nil)
    }

    // MARK: - Podcast+Convert

    @Test func podcastConvertEpisodic() throws {
        let payload = try decode("""
        {
          "id": "p1",
          "libraryId": "lib1",
          "addedAt": 1700000000000,
          "type": "episodic",
          "numEpisodes": 5,
          "numEpisodesIncomplete": 2,
          "media": {
            "metadata": {
              "title": "Pod",
              "author": "Auth",
              "description": "Desc",
              "genres": ["News"],
              "releaseDate": "2024-01-01",
              "explicit": true
            }
          }
        }
        """)
        let podcast = Podcast(payload: payload, connectionID: "conn1")
        #expect(podcast.id.primaryID == "p1")
        #expect(podcast.id.type == .podcast)
        #expect(podcast.name == "Pod")
        #expect(podcast.authors == ["Auth"])
        #expect(podcast.description == "Desc")
        #expect(podcast.genres == ["News"])
        #expect(podcast.released == "2024-01-01")
        #expect(podcast.explicit == true)
        #expect(podcast.episodeCount == 5)
        #expect(podcast.incompleteEpisodeCount == 2)
        #expect(podcast.publishingType == .episodic)
    }

    @Test func podcastConvertSerial() throws {
        let payload = try decode("""
        {
          "id": "p1",
          "libraryId": "lib1",
          "type": "serial",
          "media": {
            "metadata": {"title": "Pod", "genres": []}
          }
        }
        """)
        let podcast = Podcast(payload: payload, connectionID: "c")
        #expect(podcast.publishingType == .serial)
    }

    @Test func podcastConvertUnknownType() throws {
        let payload = try decode("""
        {
          "id": "p1",
          "libraryId": "lib1",
          "media": {
            "metadata": {"title": "Pod", "genres": []}
          }
        }
        """)
        let podcast = Podcast(payload: payload, connectionID: "c")
        #expect(podcast.publishingType == nil)
        #expect(podcast.episodeCount == 0)
        #expect(podcast.explicit == false)
    }

    @Test func podcastConvertEpisodeCountFromEpisodes() throws {
        let payload = try decode("""
        {
          "id": "p1",
          "libraryId": "lib1",
          "media": {
            "metadata": {"title": "Pod", "genres": []},
            "episodes": [
              {"id": "e1"},
              {"id": "e2"},
              {"id": "e3"}
            ]
          }
        }
        """)
        let podcast = Podcast(payload: payload, connectionID: "c")
        #expect(podcast.episodeCount == 3)
    }

    @Test func podcastConvertMultipleAuthors() throws {
        let payload = try decode("""
        {
          "id": "p1",
          "libraryId": "lib1",
          "media": {
            "metadata": {"title": "T", "author": "A, B, C", "genres": []}
          }
        }
        """)
        let podcast = Podcast(payload: payload, connectionID: "c")
        #expect(podcast.authors == ["A", "B", "C"])
    }

    // MARK: - Episode+Convert

    @Test func episodeConvertFromRecentEpisode() throws {
        let payload = try decode("""
        {
          "id": "p1",
          "libraryId": "lib1",
          "addedAt": 1700000000000,
          "recentEpisode": {
            "id": "e1",
            "title": "First",
            "description": "Desc",
            "publishedAt": 1700000000000,
            "size": 1000,
            "audioFile": {"duration": 1800},
            "season": "1",
            "episode": "5",
            "episodeType": "trailer"
          },
          "media": {
            "metadata": {
              "title": "Pod",
              "author": "Auth",
              "genres": []
            }
          }
        }
        """)
        let episode = Episode(payload: payload, connectionID: "c")
        #expect(episode != nil)
        #expect(episode?.id.primaryID == "e1")
        #expect(episode?.id.groupingID == "p1")
        #expect(episode?.id.type == .episode)
        #expect(episode?.name == "First")
        #expect(episode?.podcastName == "Pod")
        #expect(episode?.duration == 1800)
        #expect(episode?.size == 1000)
        #expect(episode?.type == .trailer)
        #expect(episode?.index.season == "1")
        #expect(episode?.index.episode == "5")
        #expect(episode?.released == "1700000000000.0")
    }

    @Test func episodeConvertNoRecentEpisodeReturnsNil() throws {
        let payload = try decode("""
        {"id": "p1", "libraryId": "lib1"}
        """)
        let episode = Episode(payload: payload, connectionID: "c")
        #expect(episode == nil)
    }

    @Test func episodeConvertBonusType() throws {
        let payload = try decode("""
        {
          "id": "p1",
          "libraryId": "lib1",
          "recentEpisode": {
            "id": "e1",
            "title": "T",
            "episodeType": "bonus"
          },
          "media": {
            "metadata": {"title": "Pod", "genres": []}
          }
        }
        """)
        let episode = Episode(payload: payload, connectionID: "c")
        #expect(episode?.type == .bonus)
    }

    @Test func episodeConvertRegularType() throws {
        let payload = try decode("""
        {
          "id": "p1",
          "libraryId": "lib1",
          "recentEpisode": {
            "id": "e1",
            "title": "T",
            "episodeType": "full"
          },
          "media": {
            "metadata": {"title": "Pod", "genres": []}
          }
        }
        """)
        let episode = Episode(payload: payload, connectionID: "c")
        #expect(episode?.type == .regular)
    }

    @Test func episodeConvertFromEpisodePayload() throws {
        let json = """
        {
          "episodes": [
            {
              "id": "e1",
              "libraryItemId": "p1",
              "title": "Title",
              "description": "Desc",
              "publishedAt": 1700000000000,
              "size": 500,
              "audioFile": {"duration": 600},
              "season": null,
              "index": 3,
              "episode": "3",
              "episodeType": "full",
              "podcast": {
                "id": "p1",
                "libraryItemId": "p1",
                "author": "Auth",
                "metadata": {
                  "title": "PodTitle",
                  "genres": []
                }
              }
            }
          ]
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(EpisodesResponse.self, from: json)
        let episode = Episode(episode: response.episodes[0], libraryID: "lib1", fallbackIndex: 99, connectionID: "c")
        #expect(episode.id.primaryID == "e1")
        #expect(episode.id.groupingID == "p1")
        #expect(episode.podcastName == "PodTitle")
        #expect(episode.duration == 600)
        #expect(episode.size == 500)
        #expect(episode.index.episode == "3")
        #expect(episode.authors == ["Auth"])
    }

    @Test func episodeConvertFromEpisodePayloadFallbackIndex() throws {
        let json = """
        {
          "episodes": [
            {
              "id": "e1",
              "libraryItemId": "p1",
              "title": "T",
              "podcast": {
                "id": "p1",
                "libraryItemId": "p1",
                "metadata": {"title": "P", "genres": []}
              }
            }
          ]
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(EpisodesResponse.self, from: json)
        let episode = Episode(episode: response.episodes[0], libraryID: "lib1", fallbackIndex: 42, connectionID: "c")
        #expect(episode.index.episode == "42")
    }

    // MARK: - Collection+Convert

    @Test func collectionConvertWithBooks() throws {
        let payload = try decode("""
        {
          "id": "col1",
          "libraryId": "lib1",
          "name": "MyCollection",
          "description": "About",
          "createdAt": 1700000000000,
          "books": [
            {
              "id": "b1",
              "libraryId": "lib1",
              "media": {
                "numAudioFiles": 1,
                "metadata": {"title": "T", "genres": []}
              }
            }
          ]
        }
        """)
        let collection = ItemCollection(payload: payload, type: .collection, connectionID: "c")
        #expect(collection.id.primaryID == "col1")
        #expect(collection.id.type == .collection)
        #expect(collection.name == "MyCollection")
        #expect(collection.items.count == 1)
        #expect(collection.audiobooks?.count == 1)
    }

    @Test func collectionConvertEmpty() throws {
        let payload = try decode("""
        {
          "id": "col1",
          "libraryId": "lib1",
          "name": "Empty"
        }
        """)
        let collection = ItemCollection(payload: payload, type: .collection, connectionID: "c")
        #expect(collection.items.isEmpty)
    }

    @Test func collectionConvertPlaylistType() throws {
        let payload = try decode("""
        {
          "id": "pl1",
          "libraryId": "lib1",
          "name": "Pl",
          "items": [
            {
              "libraryItem": {
                "id": "p1",
                "libraryId": "lib1",
                "media": {"metadata": {"title": "PodTitle", "genres": []}}
              },
              "episode": {
                "id": "e1",
                "libraryItemId": "p1",
                "title": "Ep1",
                "audioFile": {"duration": 100},
                "podcast": {
                  "id": "p1",
                  "libraryItemId": "p1",
                  "metadata": {"title": "PodTitle", "genres": []}
                }
              }
            }
          ]
        }
        """)
        let collection = ItemCollection(payload: payload, type: .playlist, connectionID: "c")
        #expect(collection.id.type == .playlist)
        #expect(collection.items.count == 1)
        #expect(collection.episodes?.count == 1)
    }

    // MARK: - Person+Convert

    @Test func personConvertAuthor() throws {
        let payload = try decode("""
        {
          "id": "auth1",
          "libraryId": "lib1",
          "name": "Auth Name",
          "description": "Bio",
          "addedAt": 1700000000000,
          "numBooks": 7
        }
        """)
        let person = Person(author: payload, connectionID: "c")
        #expect(person.id.primaryID == "auth1")
        #expect(person.id.type == .author)
        #expect(person.name == "Auth Name")
        #expect(person.description == "Bio")
        #expect(person.bookCount == 7)
    }

    @Test func personConvertAuthorMissingNumBooks() throws {
        let payload = try decode("""
        {
          "id": "auth1",
          "libraryId": "lib1",
          "name": "Auth"
        }
        """)
        let person = Person(author: payload, connectionID: "c")
        #expect(person.bookCount == 0)
    }

    @Test func personConvertNarratorByName() throws {
        let json = """
        {"id": null, "name": "Steven Fry", "numBooks": 5}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(NarratorResponse.self, from: json)
        let person = Person(narrator: response, libraryID: "lib1", connectionID: "c")
        #expect(person.name == "Steven Fry")
        #expect(person.bookCount == 5)
        #expect(person.id.type == .narrator)
    }

    @Test func personConvertNarratorByID() throws {
        let json = """
        {"id": "narr-1", "name": "Joe", "numBooks": 0}
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(NarratorResponse.self, from: json)
        let person = Person(narrator: response, libraryID: "lib1", connectionID: "c")
        #expect(person.id.primaryID == "narr-1")
    }

    @Test func convertNarratorToIDBase64() {
        let id = Person.convertNarratorToID("Hello", libraryID: "lib", connectionID: "c")
        #expect(id.type == .narrator)
        #expect(id.libraryID == "lib")
        #expect(id.connectionID == "c")
        // Plain base64 of "Hello" is "SGVsbG8=" — the implementation URL-encodes "=" to "%3D".
        #expect(id.primaryID == "SGVsbG8%3D")
    }

    @Test func convertNarratorToIDEscapesPlus() {
        // base64 of certain chars produces + or / which must be escaped
        let id = Person.convertNarratorToID(">>>", libraryID: "lib", connectionID: "c")
        #expect(!id.primaryID.contains("/"))
        #expect(!id.primaryID.contains("+"))
        #expect(!id.primaryID.contains("="))
    }

    // MARK: - PlayableItemUtility+Convert

    @Test func chapterFromPayload() throws {
        let json = """
        {"id": 0, "start": 0.0, "end": 100.0, "title": "Intro"}
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ChapterPayload.self, from: json)
        let chapter = Chapter(payload: payload)
        #expect(chapter.id == 0)
        #expect(chapter.startOffset == 0)
        #expect(chapter.endOffset == 100)
        #expect(chapter.title == "Intro")
    }

    @Test func audioFileFromTrackSuccess() throws {
        let json = """
        {
          "ino": "12345",
          "startOffset": 0,
          "duration": 300,
          "contentUrl": "/file.mp3",
          "mimeType": "audio/mpeg",
          "metadata": {"ext": ".mp3"}
        }
        """.data(using: .utf8)!
        let track = try JSONDecoder().decode(AudiobookshelfAudioTrack.self, from: json)
        let file = PlayableItem.AudioFile(track: track)
        #expect(file != nil)
        #expect(file?.ino == "12345")
        #expect(file?.fileExtension == "mp3")
        #expect(file?.offset == 0)
        #expect(file?.duration == 300)
    }

    @Test func audioFileFromTrackNoIno() throws {
        let json = """
        {
          "startOffset": 0,
          "duration": 100,
          "contentUrl": "/x",
          "mimeType": "audio/mpeg"
        }
        """.data(using: .utf8)!
        let track = try JSONDecoder().decode(AudiobookshelfAudioTrack.self, from: json)
        let file = PlayableItem.AudioFile(track: track)
        #expect(file == nil)
    }

    @Test func audioFileFromTrackNoExtensionDefaults() throws {
        let json = """
        {
          "ino": "1",
          "startOffset": 0,
          "duration": 100,
          "contentUrl": "/x",
          "mimeType": "audio/mpeg"
        }
        """.data(using: .utf8)!
        let track = try JSONDecoder().decode(AudiobookshelfAudioTrack.self, from: json)
        let file = PlayableItem.AudioFile(track: track)
        #expect(file?.fileExtension == "mp3")
    }

    @Test func audioTrackFromTrack() throws {
        let json = """
        {
          "ino": "1",
          "startOffset": 5,
          "duration": 100,
          "contentUrl": "/segment.mp3",
          "mimeType": "audio/mpeg"
        }
        """.data(using: .utf8)!
        let track = try JSONDecoder().decode(AudiobookshelfAudioTrack.self, from: json)
        let base = URL(string: "https://example.com")!
        let result = PlayableItem.AudioTrack(track: track, base: base)
        #expect(result.offset == 5)
        #expect(result.duration == 100)
        #expect(result.resource.absoluteString.contains("/segment.mp3"))
    }

    // MARK: - AudiobookSection+Convert

    @Test func audiobookSectionParseAudiobook() throws {
        let payload = try decode("""
        {
          "id": "ab1",
          "libraryId": "lib1",
          "media": {
            "numAudioFiles": 1,
            "metadata": {"title": "T", "genres": []}
          }
        }
        """)
        let section = AudiobookSection.parse(payload: payload, libraryID: "lib1", connectionID: "c")
        #expect(section != nil)
        if case .audiobook(let book) = section {
            #expect(book.id.primaryID == "ab1")
        } else {
            Issue.record("Expected audiobook case")
        }
    }

    @Test func audiobookSectionParseCollapsedSeries() throws {
        let payload = try decode("""
        {
          "id": "ignored",
          "libraryId": "lib1",
          "collapsedSeries": {
            "id": "s1",
            "name": "Saga",
            "libraryItemIds": ["b1", "b2"]
          }
        }
        """)
        let section = AudiobookSection.parse(payload: payload, libraryID: "lib1", connectionID: "c")
        if case .series(let id, let name, let bookIDs) = section {
            #expect(id.primaryID == "s1")
            #expect(id.type == .series)
            #expect(name == "Saga")
            #expect(bookIDs.count == 2)
            #expect(bookIDs.allSatisfy { $0.type == .audiobook })
        } else {
            Issue.record("Expected series case")
        }
    }

    @Test func audiobookSectionParseInvalid() throws {
        let payload = try decode("""
        {
          "id": "x",
          "libraryId": "lib1"
        }
        """)
        let section = AudiobookSection.parse(payload: payload, libraryID: "lib1", connectionID: "c")
        #expect(section == nil)
    }
}
