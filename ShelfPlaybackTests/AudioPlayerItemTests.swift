//
//  AudioPlayerItemTests.swift
//  ShelfPlaybackTests
//

import Testing
import Foundation
@testable import ShelfPlayback
import ShelfPlayerKit

struct AudioPlayerItemTests {
    // MARK: - Helpers

    private func makeIdentifier(
        primary: String = "primary",
        grouping: String? = nil,
        library: String = "lib",
        connection: String = "conn",
        type: ItemIdentifier.ItemType = .audiobook
    ) -> ItemIdentifier {
        ItemIdentifier(
            primaryID: primary,
            groupingID: grouping,
            libraryID: library,
            connectionID: connection,
            type: type
        )
    }

    /// PlaybackOrigin is not Equatable, so we compare structurally by case.
    private func matches(
        _ lhs: AudioPlayerItem.PlaybackOrigin,
        _ rhs: AudioPlayerItem.PlaybackOrigin
    ) -> Bool {
        switch (lhs, rhs) {
        case (.upNextQueue, .upNextQueue),
             (.carPlay, .carPlay),
             (.unknown, .unknown):
            return true
        case let (.series(a), .series(b)):
            return a == b
        case let (.podcast(a), .podcast(b)):
            return a == b
        case let (.collection(a), .collection(b)):
            return a == b
        default:
            return false
        }
    }

    // MARK: - AudioPlayerItem construction

    @Test func storesItemIDAndOrigin() {
        let id = makeIdentifier(primary: "ep1", grouping: "pod1", type: .episode)
        let podcastID = makeIdentifier(primary: "pod1", type: .podcast)

        let item = AudioPlayerItem(itemID: id, origin: .podcast(podcastID))

        #expect(item.itemID == id)
        #expect(matches(item.origin, .podcast(podcastID)))
    }

    @Test func instancesWithSameComponentsAreInterchangeable() {
        let id = makeIdentifier(primary: "ab1")

        let a = AudioPlayerItem(itemID: id, origin: .upNextQueue)
        let b = AudioPlayerItem(itemID: id, origin: .upNextQueue)

        #expect(a.itemID == b.itemID)
        #expect(matches(a.origin, b.origin))
    }

    @Test func differingItemIDsProduceDifferentItems() {
        let a = AudioPlayerItem(itemID: makeIdentifier(primary: "a"), origin: .unknown)
        let b = AudioPlayerItem(itemID: makeIdentifier(primary: "b"), origin: .unknown)

        #expect(a.itemID != b.itemID)
    }

    @Test func differingOriginsAreDistinguishable() {
        let id = makeIdentifier()

        let queued = AudioPlayerItem(itemID: id, origin: .upNextQueue)
        let car = AudioPlayerItem(itemID: id, origin: .carPlay)

        #expect(queued.itemID == car.itemID)
        #expect(!matches(queued.origin, car.origin))
    }

    // MARK: - PlaybackOrigin matcher

    @Test func matcherDistinguishesAllSimpleCases() {
        #expect(matches(.upNextQueue, .upNextQueue))
        #expect(matches(.carPlay, .carPlay))
        #expect(matches(.unknown, .unknown))

        #expect(!matches(.upNextQueue, .carPlay))
        #expect(!matches(.upNextQueue, .unknown))
        #expect(!matches(.carPlay, .unknown))
    }

    @Test func matcherComparesAssociatedIdentifiers() {
        let a = makeIdentifier(primary: "a", type: .series)
        let b = makeIdentifier(primary: "b", type: .series)

        #expect(matches(.series(a), .series(a)))
        #expect(!matches(.series(a), .series(b)))
        #expect(!matches(.series(a), .podcast(a)))
        #expect(!matches(.series(a), .collection(a)))
    }

    // MARK: - DisplayContext -> PlaybackOrigin mapping

    @Test func unknownDisplayContextMapsToUnknownOrigin() {
        let context: DisplayContext = .unknown
        #expect(matches(context.origin, .unknown))
    }

    @Test func personDisplayContextMapsToUnknownOrigin() {
        let person = Person(
            id: makeIdentifier(primary: "person1", type: .author),
            name: "Author",
            description: nil,
            addedAt: .distantPast,
            bookCount: 0
        )
        let context: DisplayContext = .person(person)

        #expect(matches(context.origin, .unknown))
    }

    @Test func seriesDisplayContextMapsToSeriesOrigin() {
        let seriesID = makeIdentifier(primary: "series1", type: .series)
        let series = Series(
            id: seriesID,
            name: "Series",
            authors: [],
            description: nil,
            addedAt: .distantPast,
            audiobooks: []
        )
        let context: DisplayContext = .series(series)

        #expect(matches(context.origin, .series(seriesID)))
    }

    @Test func collectionDisplayContextMapsToCollectionOrigin() {
        let collectionID = makeIdentifier(primary: "col1", type: .collection)
        let collection = ItemCollection(
            id: collectionID,
            name: "Collection",
            description: nil,
            addedAt: .distantPast,
            items: []
        )
        let context: DisplayContext = .collection(collection)

        #expect(matches(context.origin, .collection(collectionID)))
    }

    @Test func seriesOriginCarriesSeriesIdentifierVerbatim() {
        // Confirms the mapping uses the series' own id (not a derived one).
        let seriesID = makeIdentifier(
            primary: "series-primary",
            grouping: nil,
            library: "library-x",
            connection: "connection-x",
            type: .series
        )
        let series = Series(
            id: seriesID,
            name: "S",
            authors: [],
            description: nil,
            addedAt: .distantPast,
            audiobooks: []
        )

        guard case .series(let mapped) = DisplayContext.series(series).origin else {
            Issue.record("expected .series origin")
            return
        }

        #expect(mapped == seriesID)
    }

    @Test func collectionOriginCarriesCollectionIdentifierVerbatim() {
        let collectionID = makeIdentifier(
            primary: "collection-primary",
            grouping: nil,
            library: "library-y",
            connection: "connection-y",
            type: .playlist
        )
        let collection = ItemCollection(
            id: collectionID,
            name: "C",
            description: nil,
            addedAt: .distantPast,
            items: []
        )

        guard case .collection(let mapped) = DisplayContext.collection(collection).origin else {
            Issue.record("expected .collection origin")
            return
        }

        #expect(mapped == collectionID)
    }
}
