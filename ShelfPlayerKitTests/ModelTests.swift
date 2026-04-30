//
//  ModelTests.swift
//  ShelfPlayerKitTests
//

import Testing
import Foundation
@testable import ShelfPlayerKit

struct ModelTests {
    // MARK: - Audiobook

    @Test func audiobookRoundTrip() throws {
        let audiobook = Audiobook.fixture
        let encoded = try JSONEncoder().encode(audiobook)
        let decoded = try JSONDecoder().decode(Audiobook.self, from: encoded)

        #expect(decoded.id == audiobook.id)
        #expect(decoded.name == audiobook.name)
        #expect(decoded.subtitle == audiobook.subtitle)
        #expect(decoded.narrators == audiobook.narrators)
        #expect(decoded.explicit == audiobook.explicit)
        #expect(decoded.abridged == audiobook.abridged)
        #expect(decoded.duration == audiobook.duration)
        #expect(decoded.size == audiobook.size)
        #expect(decoded.series.count == audiobook.series.count)
    }

    @Test func audiobookSeriesNameSingle() {
        let book = Audiobook(
            id: .init(primaryID: "1", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook),
            name: "Book", authors: [], description: nil, genres: [], addedAt: Date(), released: nil,
            size: 0, duration: 0, subtitle: nil, narrators: [],
            series: [.init(id: nil, name: "Saga", sequence: 1.0)],
            explicit: false, abridged: false)
        #expect(book.seriesName == "Saga #1")
    }

    @Test func audiobookSeriesNameNoSequence() {
        let book = Audiobook(
            id: .init(primaryID: "1", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook),
            name: "Book", authors: [], description: nil, genres: [], addedAt: Date(), released: nil,
            size: 0, duration: 0, subtitle: nil, narrators: [],
            series: [.init(id: nil, name: "Saga", sequence: nil)],
            explicit: false, abridged: false)
        #expect(book.seriesName == "Saga")
    }

    @Test func audiobookSeriesNameEmpty() {
        let book = Audiobook(
            id: .init(primaryID: "1", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook),
            name: "Book", authors: [], description: nil, genres: [], addedAt: Date(), released: nil,
            size: 0, duration: 0, subtitle: nil, narrators: [], series: [],
            explicit: false, abridged: false)
        #expect(book.seriesName == nil)
    }

    @Test func seriesFragmentFormattedWithSequence() {
        let f = Audiobook.SeriesFragment(id: nil, name: "Saga", sequence: 2.5)
        // Decimal separator is locale-dependent ("." vs ",") — match either form.
        let expectedName = "Saga #\(f.formattedSequence ?? "")"
        #expect(f.formattedName == expectedName)
        #expect(f.formattedSequence == "2.5" || f.formattedSequence == "2,5")
    }

    @Test func seriesFragmentFormattedWholeNumber() {
        let f = Audiobook.SeriesFragment(id: nil, name: "Saga", sequence: 3.0)
        #expect(f.formattedSequence == "3")
    }

    @Test func seriesFragmentFormattedNoSequence() {
        let f = Audiobook.SeriesFragment(id: nil, name: "Saga", sequence: nil)
        #expect(f.formattedName == "Saga")
        #expect(f.formattedSequence == nil)
    }

    @Test func seriesFragmentEquality() {
        let a = Audiobook.SeriesFragment(id: nil, name: "Saga", sequence: 1)
        let b = Audiobook.SeriesFragment(id: nil, name: "Saga", sequence: 1)
        #expect(a == b)
    }

    // MARK: - Podcast

    @Test func podcastRoundTrip() throws {
        let podcast = Podcast.fixture
        let encoded = try JSONEncoder().encode(podcast)
        let decoded = try JSONDecoder().decode(Podcast.self, from: encoded)

        #expect(decoded.id == podcast.id)
        #expect(decoded.name == podcast.name)
        #expect(decoded.explicit == podcast.explicit)
        #expect(decoded.episodeCount == podcast.episodeCount)
        #expect(decoded.incompleteEpisodeCount == podcast.incompleteEpisodeCount)
        #expect(decoded.publishingType == podcast.publishingType)
    }

    @Test func podcastReleaseDateValid() {
        let podcast = Podcast(
            id: .init(primaryID: "p", groupingID: nil, libraryID: "l", connectionID: "c", type: .podcast),
            name: "P", authors: [], description: nil, genres: [], addedAt: Date(),
            released: "2023-05-21T18:00:00Z",
            explicit: false, episodeCount: 0, incompleteEpisodeCount: nil, publishingType: nil)
        #expect(podcast.releaseDate != nil)
    }

    @Test func podcastReleaseDateNil() {
        let podcast = Podcast(
            id: .init(primaryID: "p", groupingID: nil, libraryID: "l", connectionID: "c", type: .podcast),
            name: "P", authors: [], description: nil, genres: [], addedAt: Date(),
            released: nil,
            explicit: false, episodeCount: 0, incompleteEpisodeCount: nil, publishingType: nil)
        #expect(podcast.releaseDate == nil)
    }

    @Test func podcastReleaseDateInvalid() {
        let podcast = Podcast(
            id: .init(primaryID: "p", groupingID: nil, libraryID: "l", connectionID: "c", type: .podcast),
            name: "P", authors: [], description: nil, genres: [], addedAt: Date(),
            released: "not-a-date",
            explicit: false, episodeCount: 0, incompleteEpisodeCount: nil, publishingType: nil)
        #expect(podcast.releaseDate == nil)
    }

    @Test func podcastTypeRawValues() {
        #expect(Podcast.PodcastType.episodic.rawValue == 0)
        #expect(Podcast.PodcastType.serial.rawValue == 1)
    }

    // MARK: - Episode

    @Test func episodeRoundTrip() throws {
        let episode = Episode.fixture
        let encoded = try JSONEncoder().encode(episode)
        let decoded = try JSONDecoder().decode(Episode.self, from: encoded)

        #expect(decoded.id == episode.id)
        #expect(decoded.name == episode.name)
        #expect(decoded.podcastName == episode.podcastName)
        #expect(decoded.type == episode.type)
        #expect(decoded.duration == episode.duration)
    }

    @Test func episodePodcastID() {
        let episode = Episode.fixture
        let podcast = episode.podcastID
        #expect(podcast.primaryID == "fixture")
        #expect(podcast.type == .podcast)
        #expect(podcast.groupingID == nil)
    }

    @Test func episodeReleaseDateValid() {
        let episode = Episode(
            id: .init(primaryID: "e", groupingID: "p", libraryID: "l", connectionID: "c", type: .episode),
            name: "E", authors: [], description: nil, addedAt: Date(),
            released: "1698856560000",
            size: 0, duration: 0, podcastName: "P",
            type: .regular, index: .init(season: nil, episode: "1"))
        #expect(episode.releaseDate != nil)
    }

    @Test func episodeReleaseDateNil() {
        let episode = Episode(
            id: .init(primaryID: "e", groupingID: "p", libraryID: "l", connectionID: "c", type: .episode),
            name: "E", authors: [], description: nil, addedAt: Date(),
            released: nil,
            size: 0, duration: 0, podcastName: "P",
            type: .regular, index: .init(season: nil, episode: "1"))
        #expect(episode.releaseDate == nil)
    }

    @Test func episodeIndexCompareSeason() {
        let a = Episode.EpisodeIndex(season: "1", episode: "5")
        let b = Episode.EpisodeIndex(season: "2", episode: "1")
        #expect(a < b)
    }

    @Test func episodeIndexCompareEpisode() {
        let a = Episode.EpisodeIndex(season: "1", episode: "1")
        let b = Episode.EpisodeIndex(season: "1", episode: "2")
        #expect(a < b)
    }

    @Test func episodeIndexLhsHasSeason() {
        let a = Episode.EpisodeIndex(season: "1", episode: "1")
        let b = Episode.EpisodeIndex(season: nil, episode: "1")
        #expect(a < b)
        #expect(!(b < a))
    }

    @Test func episodeTypeIDs() {
        #expect(Episode.EpisodeType.regular.id == "regular")
        #expect(Episode.EpisodeType.trailer.id == "trailer")
        #expect(Episode.EpisodeType.bonus.id == "bonus")
    }

    @Test func episodeTypeAllCases() {
        #expect(Episode.EpisodeType.allCases.count == 3)
    }

    @Test func parseChapterTimestampMMSS() {
        #expect(Episode.parseChapterTimestamp("01:30") == 90)
    }

    @Test func parseChapterTimestampHHMMSS() {
        #expect(Episode.parseChapterTimestamp("01:00:00") == 3600)
    }

    @Test func parseChapterTimestampZero() {
        #expect(Episode.parseChapterTimestamp("00:00") == 0)
    }

    // MARK: - Series

    @Test func seriesRoundTrip() throws {
        let series = Series.fixture
        let encoded = try JSONEncoder().encode(series)
        let decoded = try JSONDecoder().decode(Series.self, from: encoded)

        #expect(decoded.id == series.id)
        #expect(decoded.name == series.name)
        #expect(decoded.audiobooks.count == series.audiobooks.count)
    }

    @Test func seriesEmptyAudiobooks() {
        let series = Series(
            id: .init(primaryID: "s", groupingID: nil, libraryID: "l", connectionID: "c", type: .series),
            name: "S", authors: [], description: nil, addedAt: Date(),
            audiobooks: [])
        #expect(series.audiobooks.isEmpty)
    }

    // MARK: - Person

    @Test func personRoundTrip() throws {
        let person = Person.authorFixture
        let encoded = try JSONEncoder().encode(person)
        let decoded = try JSONDecoder().decode(Person.self, from: encoded)

        #expect(decoded.id == person.id)
        #expect(decoded.name == person.name)
        #expect(decoded.bookCount == person.bookCount)
    }

    @Test func personHasNoAuthors() {
        let person = Person(
            id: .init(primaryID: "p", groupingID: nil, libraryID: "l", connectionID: "c", type: .author),
            name: "Test", description: nil, addedAt: Date(), bookCount: 5)
        #expect(person.authors.isEmpty)
        #expect(person.bookCount == 5)
    }

    // MARK: - Collection

    @Test func collectionAudiobooksAccessor() {
        let collection = ItemCollection.collectionFixture
        #expect(collection.audiobooks != nil)
        #expect(collection.episodes == nil)
    }

    @Test func collectionEpisodesAccessor() {
        let playlist = ItemCollection.playlistFixture
        #expect(playlist.episodes != nil)
        #expect(playlist.audiobooks == nil)
    }

    @Test func collectionTypeItemType() {
        #expect(ItemCollection.CollectionType.collection.itemType == .collection)
        #expect(ItemCollection.CollectionType.playlist.itemType == .playlist)
    }

    @Test func collectionTypeApiValue() {
        #expect(ItemCollection.CollectionType.collection.apiValue == "collections")
        #expect(ItemCollection.CollectionType.playlist.apiValue == "playlists")
    }

    @Test func collectionRoundTripPreservesItemTypes() throws {
        let collection = ItemCollection(
            id: .init(primaryID: "c", groupingID: nil, libraryID: "l", connectionID: "x", type: .collection),
            name: "Mixed", description: nil, addedAt: Date(),
            items: [Audiobook.fixture])
        let data = try JSONEncoder().encode(collection)
        let decoded = try JSONDecoder().decode(ItemCollection.self, from: data)

        #expect(decoded.items.count == 1)
        #expect(decoded.items[0] is Audiobook)
    }

    // MARK: - PlayableItem nested types

    @Test func audioFileInit() {
        let f = PlayableItem.AudioFile(ino: "1", fileExtension: "mp3", offset: 0, duration: 100)
        #expect(f.ino == "1")
        #expect(f.fileExtension == "mp3")
        #expect(f.offset == 0)
        #expect(f.duration == 100)
    }

    @Test func audioTrackComparable() {
        let a = PlayableItem.AudioTrack(offset: 0, duration: 100, resource: URL(string: "https://example.com/a")!)
        let b = PlayableItem.AudioTrack(offset: 100, duration: 100, resource: URL(string: "https://example.com/b")!)
        #expect(a < b)
    }

    @Test func supplementaryPDFNameStripsExtension() {
        let pdf = PlayableItem.SupplementaryPDF(ino: "1", fileName: "Companion.pdf", fileExtension: ".pdf")
        #expect(pdf.id == "1")
        #expect(pdf.name == "Companion")
    }

    // MARK: - Item

    @Test func itemSortNameStripsPrefix() {
        let book = Audiobook(
            id: .init(primaryID: "1", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook),
            name: "The Hobbit", authors: ["Tolkien"], description: nil, genres: [], addedAt: Date(), released: nil,
            size: 0, duration: 0, subtitle: nil, narrators: [], series: [],
            explicit: false, abridged: false)
        #expect(book.sortName.hasPrefix("hobbit"))
    }

    @Test func itemSortNameStripsAPrefix() {
        let book = Audiobook(
            id: .init(primaryID: "1", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook),
            name: "A Tale", authors: [], description: nil, genres: [], addedAt: Date(), released: nil,
            size: 0, duration: 0, subtitle: nil, narrators: [], series: [],
            explicit: false, abridged: false)
        #expect(book.sortName.hasPrefix("tale"))
    }

    @Test func itemEquality() {
        let id = ItemIdentifier(primaryID: "1", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook)
        let a = Audiobook(id: id, name: "A", authors: [], description: nil, genres: [], addedAt: Date(), released: nil, size: 0, duration: 0, subtitle: nil, narrators: [], series: [], explicit: false, abridged: false)
        let b = Audiobook(id: id, name: "B", authors: [], description: nil, genres: [], addedAt: Date(), released: nil, size: 0, duration: 0, subtitle: nil, narrators: [], series: [], explicit: false, abridged: false)
        #expect(a == b)
    }

    @Test func itemHashable() {
        let book = Audiobook.fixture
        let set: Set<Audiobook> = [book, book]
        #expect(set.count == 1)
    }

    // MARK: - FilterSort enums

    @Test func itemDisplayTypeNext() {
        #expect(ItemDisplayType.grid.next == .list)
        #expect(ItemDisplayType.list.next == .grid)
    }

    @Test func itemDisplayTypeID() {
        #expect(ItemDisplayType.grid.id == 0)
        #expect(ItemDisplayType.list.id == 1)
    }

    @Test func itemFilterCases() {
        #expect(ItemFilter.allCases.count == 4)
        #expect(ItemFilter.all.id == 0)
    }

    @Test func podcastFilterCases() {
        #expect(PodcastFilter.allCases.count == 3)
    }

    @Test func audiobookSortOrderRawValues() {
        #expect(AudiobookSortOrder.sortName.rawValue == "sortName")
        #expect(AudiobookSortOrder.duration.rawValue == "duration")
    }

    @Test func authorSortOrderCases() {
        #expect(AuthorSortOrder.allCases.count == 4)
    }

    @Test func narratorSortOrderCases() {
        #expect(NarratorSortOrder.allCases.count == 2)
    }

    @Test func seriesSortOrderCases() {
        #expect(SeriesSortOrder.allCases.count == 4)
    }

    @Test func episodeSortOrderCases() {
        #expect(EpisodeSortOrder.allCases.count == 4)
    }

    @Test func bookmarkSortOrderCases() {
        #expect(BookmarkSortOrder.allCases.count == 2)
    }

    @Test func podcastSortOrderCases() {
        #expect(PodcastSortOrder.allCases.count == 4)
    }

    // MARK: - HomeSection

    @Test func homeSectionStableIDServer() {
        #expect(HomeSectionKind.serverRow(id: "abc").stableID == "server::abc")
    }

    @Test func homeSectionStableIDClient() {
        #expect(HomeSectionKind.listenNowAudiobooks.stableID == "client::listenNowAudiobooks")
        #expect(HomeSectionKind.listenNowEpisodes.stableID == "client::listenNowEpisodes")
        #expect(HomeSectionKind.upNext.stableID == "client::upNext")
        #expect(HomeSectionKind.nextUpPodcasts.stableID == "client::nextUpPodcasts")
        #expect(HomeSectionKind.downloadedAudiobooks.stableID == "client::downloadedAudiobooks")
        #expect(HomeSectionKind.downloadedEpisodes.stableID == "client::downloadedEpisodes")
        #expect(HomeSectionKind.bookmarks.stableID == "client::bookmarks")
    }

    @Test func homeSectionStableIDCollection() {
        #expect(HomeSectionKind.collection(itemID: "x").stableID == "client::collection::x")
        #expect(HomeSectionKind.playlist(itemID: "y").stableID == "client::playlist::y")
    }

    @Test func homeSectionIsClientDerived() {
        #expect(!HomeSectionKind.serverRow(id: "1").isClientDerived)
        #expect(HomeSectionKind.upNext.isClientDerived)
        #expect(HomeSectionKind.bookmarks.isClientDerived)
    }

    @Test func homeSectionInitDefaults() {
        let section = HomeSection(kind: .upNext)
        #expect(section.kind == .upNext)
        #expect(section.libraryID == nil)
        #expect(section.isHidden == false)
    }

    @Test func homeSectionRoundTrip() throws {
        let section = HomeSection(id: UUID(), kind: .upNext, libraryID: nil, isHidden: true)
        let data = try JSONEncoder().encode(section)
        let decoded = try JSONDecoder().decode(HomeSection.self, from: data)
        #expect(decoded.id == section.id)
        #expect(decoded.kind == section.kind)
        #expect(decoded.isHidden == true)
    }

    @Test func homeScopeKey() {
        let lib = LibraryIdentifier(type: .audiobooks, libraryID: "lib1", connectionID: "c1")
        #expect(HomeScope.library(lib).key == "library::\(lib.id)")
        #expect(HomeScope.multiLibrary.key == "multiLibrary")
    }

    @Test func homeScopeImplicitLibraryID() {
        let lib = LibraryIdentifier(type: .audiobooks, libraryID: "lib1", connectionID: "c1")
        #expect(HomeScope.library(lib).implicitLibraryID == lib)
        #expect(HomeScope.multiLibrary.implicitLibraryID == nil)
    }

    // MARK: - AudiobookSection

    @Test func audiobookSectionAudiobookCase() {
        let section = AudiobookSection.audiobook(audiobook: Audiobook.fixture)
        #expect(section.audiobook != nil)
        #expect(section.id == Audiobook.fixture.id)
    }

    @Test func audiobookSectionSeriesCase() {
        let id = ItemIdentifier(primaryID: "s", groupingID: nil, libraryID: "l", connectionID: "c", type: .series)
        let section = AudiobookSection.series(seriesID: id, seriesName: "Saga", audiobookIDs: [])
        #expect(section.audiobook == nil)
        #expect(section.id == id)
    }

    // MARK: - Bookmark

    @Test func bookmarkID() {
        let id = ItemIdentifier(primaryID: "p", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook)
        let bookmark = Bookmark(itemID: id, time: 42, note: "Note", created: Date())
        #expect(bookmark.id.contains("42"))
    }

    @Test func bookmarkComparable() {
        let id = ItemIdentifier(primaryID: "p", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook)
        let a = Bookmark(itemID: id, time: 10, note: "", created: Date())
        let b = Bookmark(itemID: id, time: 20, note: "", created: Date())
        #expect(a < b)
    }

    // MARK: - Chapter

    @Test func chapterDuration() {
        let c = Chapter(id: 0, startOffset: 10, endOffset: 30, title: "")
        #expect(c.duration == 20)
    }

    @Test func chapterComparable() {
        let a = Chapter(id: 0, startOffset: 0, endOffset: 10, title: "")
        let b = Chapter(id: 1, startOffset: 10, endOffset: 20, title: "")
        #expect(a < b)
    }

    // MARK: - Library

    @Test func libraryInit() {
        let lib = Library(id: "id", connectionID: "c", name: "Books", type: "book", index: 0)
        #expect(lib.id.type == .audiobooks)
        #expect(lib.name == "Books")
    }

    @Test func libraryInitPodcast() {
        let lib = Library(id: "id", connectionID: "c", name: "Pods", type: "podcast", index: 1)
        #expect(lib.id.type == .podcasts)
    }

    @Test func libraryComparable() {
        let a = Library(id: "1", connectionID: "c", name: "A", type: .audiobooks, index: 0)
        let b = Library(id: "2", connectionID: "c", name: "B", type: .audiobooks, index: 1)
        #expect(a < b)
    }

    @Test func libraryIdentifierID() {
        let lib = LibraryIdentifier(type: .audiobooks, libraryID: "id", connectionID: "c")
        #expect(lib.id == "1_id_c")
    }

    @Test func libraryIdentifierEquality() {
        let a = LibraryIdentifier(type: .audiobooks, libraryID: "id", connectionID: "c")
        let b = LibraryIdentifier(type: .audiobooks, libraryID: "id", connectionID: "c")
        #expect(a == b)
    }

    @Test func libraryIdentifierConvertEpisode() {
        let itemID = ItemIdentifier(primaryID: "e", groupingID: "p", libraryID: "l", connectionID: "c", type: .episode)
        let libID = LibraryIdentifier.convertItemIdentifierToLibraryIdentifier(itemID)
        #expect(libID.type == .podcasts)
    }

    @Test func libraryIdentifierConvertAudiobook() {
        let itemID = ItemIdentifier(primaryID: "a", groupingID: nil, libraryID: "l", connectionID: "c", type: .audiobook)
        let libID = LibraryIdentifier.convertItemIdentifierToLibraryIdentifier(itemID)
        #expect(libID.type == .audiobooks)
    }

    @Test func libraryIdentifierConvertPlaylist() {
        let itemID = ItemIdentifier(primaryID: "p", groupingID: nil, libraryID: "l", connectionID: "c", type: .playlist)
        let libID = LibraryIdentifier.convertItemIdentifierToLibraryIdentifier(itemID)
        #expect(libID.type == .podcasts)
    }

    @Test func libraryMediaTypeRawValues() {
        #expect(LibraryMediaType.audiobooks.rawValue == 1)
        #expect(LibraryMediaType.podcasts.rawValue == 2)
    }

    // MARK: - ProgressEntity

    @Test func progressEntityIsFinishedTrue() {
        let entity = ProgressEntity(id: "id", connectionID: "c", primaryID: "p", groupingID: nil, progress: 1.0,
                                    duration: nil, currentTime: 0, startedAt: nil, lastUpdate: Date(), finishedAt: nil)
        #expect(entity.isFinished)
    }

    @Test func progressEntityIsFinishedFalse() {
        let entity = ProgressEntity(id: "id", connectionID: "c", primaryID: "p", groupingID: nil, progress: 0.5,
                                    duration: nil, currentTime: 0, startedAt: nil, lastUpdate: Date(), finishedAt: nil)
        #expect(!entity.isFinished)
    }

    @Test func progressEntityIsFinishedAtBoundary() {
        let entity = ProgressEntity(id: "id", connectionID: "c", primaryID: "p", groupingID: nil, progress: 1.5,
                                    duration: nil, currentTime: 0, startedAt: nil, lastUpdate: Date(), finishedAt: nil)
        #expect(entity.isFinished)
    }

    // MARK: - SleepTimerConfiguration

    @Test func sleepTimerIntervalConvenience() {
        let config = SleepTimerConfiguration.interval(60.0)
        if case .interval(_, let extend) = config {
            #expect(extend == 60.0)
        } else {
            Issue.record("Wrong case")
        }
    }

    @Test func sleepTimerChaptersConvenience() {
        let config = SleepTimerConfiguration.chapters(3)
        if case .chapters(let current, let extend) = config {
            #expect(current == 3)
            #expect(extend == 3)
        } else {
            Issue.record("Wrong case")
        }
    }

    @Test func sleepTimerExtendIntervalByPrevious() {
        let baseDate = Date()
        let config = SleepTimerConfiguration.interval(baseDate, 60)
        let extended = config.extended(byPreviousSetting: true, extendInterval: 999, extendChapterAmount: 999)

        if case .interval(let next, let extend) = extended {
            #expect(extend == 60)
            #expect(next == baseDate.advanced(by: 60))
        } else {
            Issue.record("Wrong case")
        }
    }

    @Test func sleepTimerExtendChaptersByPrevious() {
        let config = SleepTimerConfiguration.chapters(2, 5)
        let extended = config.extended(byPreviousSetting: true, extendInterval: 0, extendChapterAmount: 0)
        if case .chapters(let current, let extend) = extended {
            #expect(current == 7)
            #expect(extend == 5)
        } else {
            Issue.record("Wrong case")
        }
    }

    @Test func sleepTimerExtendChaptersByExternal() {
        let config = SleepTimerConfiguration.chapters(1, 1)
        let extended = config.extended(byPreviousSetting: false, extendInterval: 0, extendChapterAmount: 4)
        if case .chapters(let current, _) = extended {
            #expect(current == 5)
        } else {
            Issue.record("Wrong case")
        }
    }

    @Test func sleepTimerRoundTrip() throws {
        let config = SleepTimerConfiguration.chapters(3, 1)
        let data = try JSONEncoder().encode(config)
        let decoded = try JSONDecoder().decode(SleepTimerConfiguration.self, from: data)
        #expect(decoded == config)
    }

    // MARK: - TabValue

    @Test func tabValueIDAudiobookHome() {
        let lib = LibraryIdentifier(type: .audiobooks, libraryID: "l1", connectionID: "c1")
        #expect(TabValue.audiobookHome(lib).id == "audiobookHome_\(lib.id)")
    }

    @Test func tabValueIDSearch() {
        #expect(TabValue.search.id == "search")
    }

    @Test func tabValueIDLoading() {
        #expect(TabValue.loading.id == "loading")
    }

    @Test func tabValueIDMultiLibrary() {
        #expect(TabValue.multiLibrary.id == "multiLibrary")
    }

    @Test func tabValueLibraryID() {
        let lib = LibraryIdentifier(type: .audiobooks, libraryID: "l1", connectionID: "c1")
        #expect(TabValue.audiobookHome(lib).libraryID == lib)
        #expect(TabValue.search.libraryID == nil)
    }

    @Test func tabValueIsEligibleForSaving() {
        #expect(!TabValue.loading.isEligibleForSaving)
        #expect(TabValue.search.isEligibleForSaving)
    }

    @Test func tabValueCustomLibraryID() {
        let lib = LibraryIdentifier(type: .audiobooks, libraryID: "l1", connectionID: "c1")
        let custom = TabValue.custom(.audiobookHome(lib), "Foo")
        #expect(custom.libraryID == lib)
    }

    // MARK: - TintColor

    @Test func tintColorAllCases() {
        #expect(TintColor.allCases.count == 10)
    }

    @Test func tintColorIDIsSelf() {
        #expect(TintColor.purple.id == .purple)
    }

    // MARK: - AuthorizationStrategy

    @Test func authorizationStrategyRawValues() {
        #expect(AuthorizationStrategy.usernamePassword.rawValue == 0)
        #expect(AuthorizationStrategy.openID.rawValue == 1)
    }

    // MARK: - ConfigureableUpNextStrategy

    @Test func configureableUpNextRawValues() {
        #expect(ConfigureableUpNextStrategy.default.rawValue == "default")
        #expect(ConfigureableUpNextStrategy.listenNow.rawValue == "listenNow")
        #expect(ConfigureableUpNextStrategy.disabled.rawValue == "disabled")
    }

    @Test func configureableUpNextAllCases() {
        #expect(ConfigureableUpNextStrategy.allCases.count == 3)
    }

    // MARK: - DownloadStatus

    @Test func downloadStatusRawValues() {
        #expect(DownloadStatus.none.rawValue == 0)
        #expect(DownloadStatus.downloading.rawValue == 1)
        #expect(DownloadStatus.completed.rawValue == 2)
    }

    @Test func downloadStatusAllCases() {
        #expect(DownloadStatus.allCases.count == 3)
    }

    @Test func downloadStatusRoundTrip() throws {
        let status = DownloadStatus.completed
        let data = try JSONEncoder().encode(status)
        let decoded = try JSONDecoder().decode(DownloadStatus.self, from: data)
        #expect(decoded == status)
    }
}
