//
//  ChannelTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct ChannelTests {
    private func podcast(_ name: String, authors: [String], library: String = "lib", connection: String = "conn") -> Podcast {
        Podcast(
            id: .init(primaryID: name, groupingID: nil, libraryID: library, connectionID: connection, type: .podcast),
            name: name,
            authors: authors,
            description: nil,
            genres: [],
            addedAt: .distantPast,
            released: nil,
            explicit: false,
            episodeCount: 0,
            incompleteEpisodeCount: nil,
            publishingType: nil)
    }

    // MARK: - Identity

    @Test func nameIDRoundTrip() {
        let names = ["Deutschlandfunk Kultur", "DER SPIEGEL", "Söhne Mannheims", "A/B+C=D", "single"]

        for name in names {
            let id = Channel.convertNameToID(name, libraryID: "lib1", connectionID: "conn1")

            #expect(id.type == .channel)
            #expect(id.libraryID == "lib1")
            #expect(id.connectionID == "conn1")
            #expect(Channel.decodeName(from: id) == name)
        }
    }

    @Test func identifierStringRoundTripPreservesChannel() {
        let id = Channel.convertNameToID("Deutschlandfunk Kultur", libraryID: "lib1", connectionID: "conn1")
        let parsed = ItemIdentifier(string: id.description)

        #expect(parsed.type == .channel)
        #expect(Channel.decodeName(from: parsed) == "Deutschlandfunk Kultur")
    }

    // MARK: - Grouping

    @Test func groupsPodcastsByAuthor() {
        let p1 = podcast("First", authors: ["A"])
        let p2 = podcast("Second", authors: ["B"])
        let p3 = podcast("Third", authors: ["A", "B"])

        let channels = Channel.grouped(from: [p1, p2, p3])

        #expect(channels.count == 2)

        let a = try! #require(channels.first { $0.name == "A" })
        let b = try! #require(channels.first { $0.name == "B" })

        #expect(Set(a.podcasts.map(\.name)) == ["First", "Third"])
        #expect(Set(b.podcasts.map(\.name)) == ["Second", "Third"])

        // The channel identity is derived from the author name.
        #expect(a.id == Channel.convertNameToID("A", libraryID: "lib", connectionID: "conn"))
    }

    @Test func groupingTrimsWhitespaceAndSkipsEmptyAuthors() {
        let channels = Channel.grouped(from: [
            podcast("First", authors: ["  Spaced  ", ""]),
            podcast("Second", authors: ["Spaced"]),
        ])

        #expect(channels.count == 1)
        #expect(channels.first?.name == "Spaced")
        #expect(channels.first?.podcasts.count == 2)
    }

    @Test func groupingEmptyInputYieldsNoChannels() {
        #expect(Channel.grouped(from: []).isEmpty)
    }

    // MARK: - Monogram

    @Test func monogramRule() {
        #expect(Channel.monogram(for: "Deutschlandfunk") == "D")
        #expect(Channel.monogram(for: "DER SPIEGEL") == "DS")
        #expect(Channel.monogram(for: "The New York Times") == "TNY")
        #expect(Channel.monogram(for: "A B C D E") == "ABC")
        #expect(Channel.monogram(for: "1984") == "1")
    }
}
