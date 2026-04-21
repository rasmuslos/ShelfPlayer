//
//  ItemIdentifierTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct ItemIdentifierTests {
    @Test func roundTrip() {
        let identifier = ItemIdentifier(
            primaryID: "abc123",
            groupingID: nil,
            libraryID: "lib1",
            connectionID: "conn1",
            type: .audiobook
        )

        let string = identifier.description
        let parsed = ItemIdentifier(string: string)

        #expect(parsed.primaryID == "abc123")
        #expect(parsed.groupingID == nil)
        #expect(parsed.libraryID == "lib1")
        #expect(parsed.connectionID == "conn1")
        #expect(parsed.type == .audiobook)
    }

    @Test func roundTripWithGroupingID() {
        let identifier = ItemIdentifier(
            primaryID: "ep1",
            groupingID: "pod1",
            libraryID: "lib2",
            connectionID: "conn2",
            type: .episode
        )

        let string = identifier.description
        let parsed = ItemIdentifier(string: string)

        #expect(parsed.primaryID == "ep1")
        #expect(parsed.groupingID == "pod1")
        #expect(parsed.libraryID == "lib2")
        #expect(parsed.connectionID == "conn2")
        #expect(parsed.type == .episode)
    }

    @Test func format() {
        let identifier = ItemIdentifier(
            primaryID: "primary",
            groupingID: nil,
            libraryID: "library",
            connectionID: "connection",
            type: .audiobook
        )

        #expect(identifier.description == "1::audiobook::connection::library::primary")
    }

    @Test func formatWithGrouping() {
        let identifier = ItemIdentifier(
            primaryID: "primary",
            groupingID: "grouping",
            libraryID: "library",
            connectionID: "connection",
            type: .episode
        )

        #expect(identifier.description == "1::episode::connection::library::primary::grouping")
    }

    @Test func isValid() {
        #expect(ItemIdentifier.isValid("1::audiobook::conn::lib::primary"))
        #expect(ItemIdentifier.isValid("1::episode::conn::lib::primary::grouping"))
        #expect(!ItemIdentifier.isValid("2::audiobook::conn::lib::primary"))
        #expect(!ItemIdentifier.isValid("invalid"))
        #expect(!ItemIdentifier.isValid("1::audiobook::conn"))
    }

    @Test func equality() {
        let a = ItemIdentifier(primaryID: "1", groupingID: nil, libraryID: "lib", connectionID: "conn", type: .audiobook)
        let b = ItemIdentifier(primaryID: "1", groupingID: nil, libraryID: "lib", connectionID: "conn", type: .audiobook)
        let c = ItemIdentifier(primaryID: "2", groupingID: nil, libraryID: "lib", connectionID: "conn", type: .audiobook)

        #expect(a == b)
        #expect(a != c)
    }

    @Test func isPlayable() {
        let audiobook = ItemIdentifier(primaryID: "1", groupingID: nil, libraryID: "lib", connectionID: "conn", type: .audiobook)
        let episode = ItemIdentifier(primaryID: "1", groupingID: "pod", libraryID: "lib", connectionID: "conn", type: .episode)
        let podcast = ItemIdentifier(primaryID: "1", groupingID: nil, libraryID: "lib", connectionID: "conn", type: .podcast)
        let author = ItemIdentifier(primaryID: "1", groupingID: nil, libraryID: "lib", connectionID: "conn", type: .author)

        #expect(audiobook.isPlayable)
        #expect(episode.isPlayable)
        #expect(!podcast.isPlayable)
        #expect(!author.isPlayable)
    }

    @Test func convertEpisodeToPodcast() {
        let episode = ItemIdentifier(primaryID: "ep1", groupingID: "pod1", libraryID: "lib", connectionID: "conn", type: .episode)
        let podcast = ItemIdentifier.convertEpisodeIdentifierToPodcastIdentifier(episode)

        #expect(podcast.primaryID == "pod1")
        #expect(podcast.groupingID == nil)
        #expect(podcast.type == .podcast)
    }
}
