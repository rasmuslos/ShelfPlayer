//
//  ResolveTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct ResolveTests {
    // MARK: - ItemID+API

    @Test func pathComponentWithoutGrouping() {
        let id = ItemIdentifier(
            primaryID: "book-1",
            groupingID: nil,
            libraryID: "lib",
            connectionID: "conn",
            type: .audiobook
        )

        #expect(id.pathComponent == "book-1")
    }

    @Test func pathComponentWithGrouping() {
        let id = ItemIdentifier(
            primaryID: "ep-7",
            groupingID: "pod-3",
            libraryID: "lib",
            connectionID: "conn",
            type: .episode
        )

        #expect(id.pathComponent == "pod-3/ep-7")
    }

    @Test func apiItemIDPrefersGrouping() {
        let id = ItemIdentifier(
            primaryID: "ep-7",
            groupingID: "pod-3",
            libraryID: "lib",
            connectionID: "conn",
            type: .episode
        )

        #expect(id.apiItemID == "pod-3")
    }

    @Test func apiItemIDFallsBackToPrimary() {
        let id = ItemIdentifier(
            primaryID: "book-1",
            groupingID: nil,
            libraryID: "lib",
            connectionID: "conn",
            type: .audiobook
        )

        #expect(id.apiItemID == "book-1")
    }

    @Test func apiEpisodeIDIsPrimaryWhenGrouped() {
        let id = ItemIdentifier(
            primaryID: "ep-7",
            groupingID: "pod-3",
            libraryID: "lib",
            connectionID: "conn",
            type: .episode
        )

        #expect(id.apiEpisodeID == "ep-7")
    }

    @Test func apiEpisodeIDIsNilWithoutGrouping() {
        let id = ItemIdentifier(
            primaryID: "book-1",
            groupingID: nil,
            libraryID: "lib",
            connectionID: "conn",
            type: .audiobook
        )

        #expect(id.apiEpisodeID == nil)
    }

    // MARK: - ItemID+URL
    //
    // The `url` getter resolves the connection's host through the live
    // PersistenceManager singleton. Without a registered connection it must
    // throw `PersistenceError.serverNotFound`.

    @Test func urlThrowsWhenServerUnknown() async {
        let id = ItemIdentifier(
            primaryID: "p",
            groupingID: nil,
            libraryID: "lib",
            connectionID: "definitely-not-a-real-connection-\(UUID().uuidString)",
            type: .audiobook
        )

        await #expect(throws: (any Error).self) {
            _ = try await id.url
        }
    }

    // MARK: - SortOrder+URL

    @Test func audiobookSortOrderQueryValues() {
        #expect(AudiobookSortOrder.sortName.queryValue == "media.metadata.title")
        #expect(AudiobookSortOrder.authorName.queryValue == "media.metadata.authorName")
        #expect(AudiobookSortOrder.released.queryValue == "media.metadata.publishedYear")
        #expect(AudiobookSortOrder.added.queryValue == "addedAt")
        #expect(AudiobookSortOrder.duration.queryValue == "media.duration")
    }

    @Test func authorSortOrderQueryValues() {
        #expect(AuthorSortOrder.firstNameLastName.queryValue == "name")
        #expect(AuthorSortOrder.lastNameFirstName.queryValue == "lastFirst")
        #expect(AuthorSortOrder.bookCount.queryValue == "numBooks")
        #expect(AuthorSortOrder.added.queryValue == "addedAt")
    }

    @Test func seriesSortOrderQueryValues() {
        #expect(SeriesSortOrder.sortName.queryValue == "name")
        #expect(SeriesSortOrder.bookCount.queryValue == "numBooks")
        #expect(SeriesSortOrder.added.queryValue == "addedAt")
        #expect(SeriesSortOrder.duration.queryValue == "totalDuration")
    }

    @Test func podcastSortOrderQueryValues() {
        #expect(PodcastSortOrder.name.queryValue == "media.metadata.title")
        #expect(PodcastSortOrder.author.queryValue == "media.metadata.author")
        #expect(PodcastSortOrder.episodeCount.queryValue == "media.numTracks")
        #expect(PodcastSortOrder.addedAt.queryValue == "addedAt")
    }

    @Test func sortOrderQueryValuesAreNonEmpty() {
        for value in AudiobookSortOrder.allCases {
            #expect(!value.queryValue.isEmpty)
        }
        for value in AuthorSortOrder.allCases {
            #expect(!value.queryValue.isEmpty)
        }
        for value in SeriesSortOrder.allCases {
            #expect(!value.queryValue.isEmpty)
        }
        for value in PodcastSortOrder.allCases {
            #expect(!value.queryValue.isEmpty)
        }
    }
}
