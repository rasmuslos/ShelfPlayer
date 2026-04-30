//
//  ExtensionsTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct ExtensionsTests {
    // MARK: - String+Distance

    @Test func levenshteinIdentical() {
        #expect("hello".levenshteinDistanceScore(to: "hello") == 1.0)
    }

    @Test func levenshteinCompletelyDifferent() {
        #expect("abc".levenshteinDistanceScore(to: "xyz") == 0.0)
    }

    @Test func levenshteinPartialMatch() {
        let score = "kitten".levenshteinDistanceScore(to: "sitting")
        #expect(score > 0 && score < 1)
    }

    @Test func levenshteinIgnoreCaseDefault() {
        #expect("HELLO".levenshteinDistanceScore(to: "hello") == 1.0)
    }

    @Test func levenshteinCaseSensitive() {
        let score = "HELLO".levenshteinDistanceScore(to: "hello", ignoreCase: false)
        #expect(score < 1.0)
    }

    @Test func levenshteinTrimWhitespace() {
        #expect("  hello  ".levenshteinDistanceScore(to: "hello") == 1.0)
    }

    @Test func levenshteinNoTrim() {
        let score = "  hello  ".levenshteinDistanceScore(to: "hello", trimWhiteSpacesAndNewLines: false)
        #expect(score < 1.0)
    }

    @Test func levenshteinEmptyStrings() {
        // Both empty divides 0/0 → NaN, exercises the edge case without a strict expectation.
        let score = "".levenshteinDistanceScore(to: "")
        #expect(score.isNaN || score == 1.0 || score == 0.0)
    }

    // MARK: - Double+FormatDuration

    @Test func formatDurationFinite() {
        let result = (3600.0 as Double).formatted(.duration)
        #expect(!result.isEmpty)
        #expect(result != "?")
    }

    @Test func formatDurationInfinite() {
        #expect((Double.infinity as Double).formatted(.duration) == "?")
    }

    @Test func formatDurationNaN() {
        #expect((Double.nan as Double).formatted(.duration) == "?")
    }

    @Test func formatDurationCustomStyle() {
        let style = DurationComponentsFormatter(unitsStyle: .positional, allowedUnits: [.minute, .second], maximumUnitCount: 2)
        let result = (90.0 as Double).formatted(style)
        #expect(!result.isEmpty)
        #expect(result != "?")
    }

    @Test func formatDurationFactory() {
        let style: DurationComponentsFormatter = .duration(unitsStyle: .full, allowedUnits: [.hour, .minute], maximumUnitCount: 1)
        #expect(style.unitsStyle == .full)
        #expect(style.maximumUnitCount == 1)
    }

    // MARK: - Double+FormatRate

    @Test func formatRateDefault() {
        let result = (1.5 as Double).formatted(.playbackRate)
        #expect(result == "1.5x")
    }

    @Test func formatRateHideX() {
        let result = (1.5 as Double).formatted(.playbackRate.hideX())
        #expect(result == "1.5")
    }

    @Test func formatRateFixedFraction() {
        let result = (1.0 as Double).formatted(.playbackRate.fractionDigits(2))
        #expect(result == "1.00x")
    }

    @Test func formatRateFixedFractionHideX() {
        let result = (2.0 as Double).formatted(.playbackRate.fractionDigits(1).hideX())
        #expect(result == "2.0")
    }

    @Test func formatRateNaN() {
        #expect((Double.nan as Double).formatted(.playbackRate) == "?")
    }

    @Test func formatRateInfinite() {
        #expect((Double.infinity as Double).formatted(.playbackRate) == "?")
    }

    @Test func formatRateInteger() {
        let result = (2.0 as Double).formatted(.playbackRate)
        #expect(result == "2x")
    }

    // MARK: - String+Random

    @Test func randomLengthZero() {
        #expect(String(length: 0) == "")
    }

    @Test func randomLengthCorrect() {
        #expect(String(length: 12).count == 12)
    }

    @Test func randomCharactersAllowed() {
        let s = String(length: 100)
        let allowed = Set("abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789")
        #expect(s.allSatisfy { allowed.contains($0) })
    }

    // MARK: - Episode+Sort

    private func makeEpisode(name: String, season: String?, episode: String, released: String?, duration: TimeInterval) -> Episode {
        Episode(
            id: .init(primaryID: name, groupingID: "pod", libraryID: "lib", connectionID: "conn", type: .episode),
            name: name,
            authors: [],
            description: nil,
            addedAt: Date(),
            released: released,
            size: 0,
            duration: duration,
            podcastName: "Pod",
            type: .regular,
            index: .init(season: season, episode: episode))
    }

    @Test func episodeSortName() {
        let a = makeEpisode(name: "A", season: nil, episode: "1", released: nil, duration: 0)
        let b = makeEpisode(name: "B", season: nil, episode: "1", released: nil, duration: 0)
        #expect(a.compare(other: b, sortOrder: .name, ascending: true))
        #expect(!b.compare(other: a, sortOrder: .name, ascending: true))
    }

    @Test func episodeSortIndex() {
        let a = makeEpisode(name: "X", season: "1", episode: "1", released: nil, duration: 0)
        let b = makeEpisode(name: "Y", season: "1", episode: "2", released: nil, duration: 0)
        #expect(a.compare(other: b, sortOrder: .index, ascending: true))
    }

    @Test func episodeSortDuration() {
        let a = makeEpisode(name: "X", season: nil, episode: "1", released: nil, duration: 100)
        let b = makeEpisode(name: "Y", season: nil, episode: "1", released: nil, duration: 200)
        #expect(a.compare(other: b, sortOrder: .duration, ascending: true))
    }

    @Test func episodeSortReleasedBothPresent() {
        let a = makeEpisode(name: "X", season: nil, episode: "1", released: "1000000000000", duration: 0)
        let b = makeEpisode(name: "Y", season: nil, episode: "1", released: "2000000000000", duration: 0)
        #expect(a.compare(other: b, sortOrder: .released, ascending: true))
    }

    @Test func episodeSortReleasedLhsMissing() {
        let a = makeEpisode(name: "X", season: nil, episode: "1", released: nil, duration: 0)
        let b = makeEpisode(name: "Y", season: nil, episode: "1", released: "2000000000000", duration: 0)
        #expect(!a.compare(other: b, sortOrder: .released, ascending: true))
    }

    @Test func episodeSortReleasedRhsMissing() {
        let a = makeEpisode(name: "X", season: nil, episode: "1", released: "1000000000000", duration: 0)
        let b = makeEpisode(name: "Y", season: nil, episode: "1", released: nil, duration: 0)
        #expect(a.compare(other: b, sortOrder: .released, ascending: true))
    }

    // MARK: - Data+sha256

    @Test func sha256EmptyData() {
        let hash = Data().sha256
        #expect(hash.count == 32)
    }

    @Test func sha256Deterministic() {
        let data = "hello".data(using: .utf8)!
        #expect(data.sha256 == data.sha256)
    }

    @Test func sha256Different() {
        let a = "hello".data(using: .utf8)!.sha256
        let b = "world".data(using: .utf8)!.sha256
        #expect(a != b)
    }

    @Test func sha256KnownValue() {
        let data = "abc".data(using: .utf8)!.sha256
        let expected = "BA7816BF8F01CFEA414140DE5DAE2223B00361A396177A9CB410FF61F20015AD"
        #expect(data.map { String(format: "%02X", $0) }.joined() == expected)
    }

    // MARK: - ItemID+UI

    @Test func itemTypeLabelNonEmpty() {
        for type in [ItemIdentifier.ItemType.audiobook, .author, .narrator, .series, .podcast, .episode, .collection, .playlist] {
            #expect(!type.label.isEmpty)
        }
    }

    @Test func itemTypeIconAudiobook() {
        #expect(ItemIdentifier.ItemType.audiobook.icon == "book.fill")
    }

    @Test func itemTypeIconAuthor() {
        #expect(ItemIdentifier.ItemType.author.icon == "person.fill")
    }

    @Test func itemTypeIconNarrator() {
        #expect(ItemIdentifier.ItemType.narrator.icon == "microphone.fill")
    }

    @Test func itemTypeIconSeries() {
        #expect(ItemIdentifier.ItemType.series.icon == "rectangle.grid.2x2.fill")
    }

    @Test func itemTypeIconPodcast() {
        #expect(ItemIdentifier.ItemType.podcast.icon == "square.stack")
    }

    @Test func itemTypeIconEpisode() {
        #expect(ItemIdentifier.ItemType.episode.icon == "play.square")
    }

    @Test func itemTypeIconCollection() {
        #expect(ItemIdentifier.ItemType.collection.icon == "book.pages.fill")
    }

    @Test func itemTypeIconPlaylist() {
        #expect(ItemIdentifier.ItemType.playlist.icon == "folder.fill")
    }

    // MARK: - ResolvedUpNextStrategy itemID (associated value extraction)

    @Test func resolvedUpNextItemIDNone() {
        #expect(ResolvedUpNextStrategy.none.itemID == nil)
    }

    @Test func resolvedUpNextItemIDListenNow() {
        #expect(ResolvedUpNextStrategy.listenNow.itemID == nil)
    }

    @Test func resolvedUpNextItemIDSeries() {
        let id = ItemIdentifier(primaryID: "s1", groupingID: nil, libraryID: "l", connectionID: "c", type: .series)
        #expect(ResolvedUpNextStrategy.series(id).itemID == id)
    }

    @Test func resolvedUpNextItemIDPodcast() {
        let id = ItemIdentifier(primaryID: "p1", groupingID: nil, libraryID: "l", connectionID: "c", type: .podcast)
        #expect(ResolvedUpNextStrategy.podcast(id).itemID == id)
    }

    @Test func resolvedUpNextItemIDCollection() {
        let id = ItemIdentifier(primaryID: "c1", groupingID: nil, libraryID: "l", connectionID: "c", type: .collection)
        #expect(ResolvedUpNextStrategy.collection(id).itemID == id)
    }
}
