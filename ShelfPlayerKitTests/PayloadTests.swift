//
//  PayloadTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct PayloadTests {
    // MARK: - ItemPayload

    @Test func itemPayloadDecodeMinimal() throws {
        let json = """
        {"id":"item1"}
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ItemPayload.self, from: json)
        #expect(payload.id == "item1")
        #expect(payload.libraryId == nil)
        #expect(payload.media == nil)
    }

    @Test func itemPayloadDecodeAudiobookFull() throws {
        let json = """
        {
          "id": "ab1",
          "libraryId": "lib1",
          "mediaType": "book",
          "addedAt": 1700000000000,
          "size": 12345,
          "media": {
            "duration": 7200,
            "metadata": {
              "title": "Title",
              "subtitle": "Sub",
              "authorName": "Author A, Author B",
              "narratorName": "Narrator",
              "publishedYear": "2020",
              "description": "<p>Desc</p>",
              "genres": ["Genre"],
              "explicit": false,
              "abridged": false,
              "series": []
            }
          }
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ItemPayload.self, from: json)
        #expect(payload.id == "ab1")
        #expect(payload.libraryId == "lib1")
        #expect(payload.size == 12345)
        #expect(payload.media?.metadata.title == "Title")
        #expect(payload.media?.metadata.authorName == "Author A, Author B")
    }

    @Test func itemPayloadDecodeMissingIDThrows() {
        let json = "{}".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(ItemPayload.self, from: json)
        }
    }

    @Test func itemPayloadDecodeMalformedThrows() {
        let json = "not-json".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(ItemPayload.self, from: json)
        }
    }

    @Test func itemPayloadFallbackToPlaylistItems() throws {
        let json = """
        {
          "id": "playlist1",
          "items": [
            {"libraryItem": {"id": "lib1"}},
            {"libraryItem": {"id": "lib2"}}
          ]
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ItemPayload.self, from: json)
        #expect(payload.items == nil)
        #expect(payload.playlistItems?.count == 2)
    }

    @Test func itemPayloadItemsArray() throws {
        let json = """
        {
          "id": "c1",
          "items": [
            {"id": "a1"},
            {"id": "a2"}
          ]
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ItemPayload.self, from: json)
        #expect(payload.items?.count == 2)
        #expect(payload.playlistItems == nil)
    }

    // MARK: - MetadataPayload series shape

    @Test func metadataPayloadSeriesArray() throws {
        let json = """
        {
          "id": "1",
          "media": {
            "metadata": {
              "title": "Title",
              "genres": [],
              "series": [{"id": "s1", "name": "Saga", "sequence": "1"}]
            }
          }
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ItemPayload.self, from: json)
        #expect(payload.media?.metadata.series?.count == 1)
        #expect(payload.media?.metadata.series?.first?.name == "Saga")
    }

    @Test func metadataPayloadSeriesSingle() throws {
        let json = """
        {
          "id": "1",
          "media": {
            "metadata": {
              "title": "T",
              "genres": [],
              "series": {"id": "s1", "name": "Saga", "sequence": "2"}
            }
          }
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ItemPayload.self, from: json)
        #expect(payload.media?.metadata.series?.count == 1)
    }

    @Test func metadataPayloadSeriesMissing() throws {
        let json = """
        {
          "id": "1",
          "media": {
            "metadata": {
              "title": "T",
              "genres": []
            }
          }
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ItemPayload.self, from: json)
        #expect(payload.media?.metadata.series?.isEmpty == true)
    }

    // MARK: - ProgressPayload

    @Test func progressPayloadDecode() throws {
        let json = """
        {
          "id": "prog1",
          "libraryItemId": "lib1",
          "episodeId": null,
          "duration": 3600,
          "progress": 0.5,
          "currentTime": 1800,
          "isFinished": false,
          "hideFromContinueListening": false,
          "lastUpdate": 1700000000000,
          "startedAt": 1699000000000,
          "finishedAt": null
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ProgressPayload.self, from: json)
        #expect(payload.id == "prog1")
        #expect(payload.libraryItemId == "lib1")
        #expect(payload.episodeId == nil)
        #expect(payload.duration == 3600)
        #expect(payload.progress == 0.5)
        #expect(payload.currentTime == 1800)
        #expect(payload.isFinished == false)
        #expect(payload.lastUpdate == 1_700_000_000_000)
        #expect(payload.startedAt == 1_699_000_000_000)
        #expect(payload.finishedAt == nil)
    }

    @Test func progressPayloadFinished() throws {
        let json = """
        {
          "id": "prog2",
          "libraryItemId": "lib1",
          "isFinished": true
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ProgressPayload.self, from: json)
        #expect(payload.isFinished)
        #expect(payload.duration == nil)
    }

    @Test func progressPayloadMissingRequiredThrows() {
        let json = "{\"id\":\"x\"}".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(ProgressPayload.self, from: json)
        }
    }

    // MARK: - SessionPayload

    @Test func sessionPayloadDecode() throws {
        let json = """
        {
          "id": "s1",
          "userId": "u1",
          "libraryId": "l1",
          "libraryItemId": "i1",
          "mediaType": "book",
          "duration": 3600,
          "playMethod": 0,
          "mediaPlayer": "ShelfPlayer",
          "serverVersion": "2.0.0",
          "timeListening": 600,
          "startTime": 0,
          "currentTime": 600,
          "startedAt": 1700000000000,
          "updatedAt": 1700000600000
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(SessionPayload.self, from: json)
        #expect(payload.id == "s1")
        #expect(payload.duration == 3600)
        #expect(payload.startTime == 0)
        #expect(payload.startedAt == 1_700_000_000_000)
    }

    @Test func sessionPayloadDates() {
        let payload = SessionPayload.fixture
        #expect(payload.startDate.timeIntervalSince1970 == 1668330137.087)
        #expect(payload.endDate.timeIntervalSince1970 == 1668330152.157)
    }

    @Test func sessionPayloadDecodeMissingRequiredThrows() {
        let json = "{\"id\":\"s1\"}".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(SessionPayload.self, from: json)
        }
    }

    @Test func deviceInfoDecode() throws {
        let json = """
        {
          "id": "d1",
          "userId": "u1",
          "deviceId": "device1",
          "browserName": "ShelfPlayer",
          "osName": "iOS",
          "osVersion": "26.0",
          "deviceType": "Phone",
          "manufacturer": "Apple",
          "model": "iPhone17,1",
          "clientName": "ShelfPlayer",
          "clientVersion": "1.0.0"
        }
        """.data(using: .utf8)!
        let info = try JSONDecoder().decode(SessionPayload.DeviceInfo.self, from: json)
        #expect(info.id == "d1")
        #expect(info.osName == "iOS")
        #expect(info.manufacturer == "Apple")
    }

    // MARK: - ListeningStatsPayload

    @Test func listeningStatsDecode() throws {
        let json = """
        {
          "totalTime": 7200,
          "items": {
            "abc": {
              "id": "abc",
              "timeListening": 3600,
              "mediaMetadata": {
                "title": "Book",
                "author": "Auth"
              }
            }
          },
          "days": {"2024-01-01": 1000.0},
          "dayOfWeek": {"Monday": 500.0},
          "today": 250.0,
          "recentSessions": []
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(ListeningStatsPayload.self, from: json)
        #expect(payload.totalTime == 7200)
        #expect(payload.items["abc"]?.timeListening == 3600)
        #expect(payload.days["2024-01-01"] == 1000)
        #expect(payload.today == 250)
        #expect(payload.recentSessions.isEmpty)
    }

    @Test func mediaMetadataResolvedAuthorPrefersAuthor() {
        let metadata = ListeningStatsPayload.MediaMetadata(title: "T", author: "A", authorName: "B")
        #expect(metadata.resolvedAuthor == "A")
    }

    @Test func mediaMetadataResolvedAuthorFallback() {
        let metadata = ListeningStatsPayload.MediaMetadata(title: "T", author: nil, authorName: "B")
        #expect(metadata.resolvedAuthor == "B")
    }

    @Test func mediaMetadataResolvedAuthorNil() {
        let metadata = ListeningStatsPayload.MediaMetadata(title: "T", author: nil, authorName: nil)
        #expect(metadata.resolvedAuthor == nil)
    }

    // MARK: - UtilityPayload

    @Test func bookmarkPayloadDecode() throws {
        let json = """
        {
          "libraryItemId": "li1",
          "title": "Bookmark Note",
          "time": 3600.5,
          "createdAt": 1700000000000
        }
        """.data(using: .utf8)!
        let payload = try JSONDecoder().decode(BookmarkPayload.self, from: json)
        #expect(payload.libraryItemId == "li1")
        #expect(payload.title == "Bookmark Note")
        #expect(payload.time == 3600.5)
        #expect(payload.createdAt == 1_700_000_000_000)
    }

    @Test func bookmarkPayloadMissingRequiredThrows() {
        let json = "{\"libraryItemId\":\"li1\"}".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(BookmarkPayload.self, from: json)
        }
    }

    @Test func userPermissionsRoundTrip() throws {
        let perms = UserPermissionsPayload(
            download: true, update: false, delete: true, upload: false,
            accessAllLibraries: true, accessAllTags: false, accessExplicitContent: true)
        let data = try JSONEncoder().encode(perms)
        let decoded = try JSONDecoder().decode(UserPermissionsPayload.self, from: data)
        #expect(decoded == perms)
    }

    @Test func userPermissionsHashable() {
        let perms = UserPermissionsPayload(
            download: true, update: true, delete: true, upload: true,
            accessAllLibraries: true, accessAllTags: true, accessExplicitContent: true)
        let set: Set<UserPermissionsPayload> = [perms, perms]
        #expect(set.count == 1)
    }

    @Test func statusResponseDecode() throws {
        let json = """
        {
          "isInit": true,
          "authMethods": ["local", "openid"],
          "serverVersion": "2.5.0"
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder().decode(StatusResponse.self, from: json)
        #expect(response.isInit == true)
        #expect(response.authMethods == ["local", "openid"])
        #expect(response.serverVersion == "2.5.0")
    }

    @Test func statusResponseMissingRequiredThrows() {
        let json = "{\"isInit\":true}".data(using: .utf8)!
        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(StatusResponse.self, from: json)
        }
    }
}
