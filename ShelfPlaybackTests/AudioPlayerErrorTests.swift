//
//  AudioPlayerErrorTests.swift
//  ShelfPlaybackTests
//

import Testing
import Foundation
@testable import ShelfPlayback

struct AudioPlayerErrorTests {
    /// `AudioPlayerError` does not declare `Equatable` conformance, so we
    /// compare via pattern matching rather than `==`.
    private func matches(_ lhs: AudioPlayerError, _ rhs: AudioPlayerError) -> Bool {
        switch (lhs, rhs) {
        case (.offline, .offline),
             (.downloading, .downloading),
             (.invalidTime, .invalidTime),
             (.missingAudioTrack, .missingAudioTrack),
             (.loadFailed, .loadFailed),
             (.itemMissing, .itemMissing),
             (.invalidItemType, .invalidItemType):
            return true
        default:
            return false
        }
    }

    @Test func selfMatching() {
        #expect(matches(.offline, .offline))
        #expect(matches(.downloading, .downloading))
        #expect(matches(.invalidTime, .invalidTime))
        #expect(matches(.missingAudioTrack, .missingAudioTrack))
        #expect(matches(.loadFailed, .loadFailed))
        #expect(matches(.itemMissing, .itemMissing))
        #expect(matches(.invalidItemType, .invalidItemType))
    }

    @Test func crossCaseDoesNotMatch() {
        #expect(!matches(.offline, .downloading))
        #expect(!matches(.invalidTime, .missingAudioTrack))
        #expect(!matches(.loadFailed, .itemMissing))
        #expect(!matches(.invalidItemType, .offline))
        #expect(!matches(.missingAudioTrack, .loadFailed))
        #expect(!matches(.downloading, .invalidItemType))
        #expect(!matches(.itemMissing, .invalidTime))
    }

    @Test func conformsToErrorProtocol() {
        // Any thrown AudioPlayerError must be catchable as a Swift Error
        // and re-castable back to its enum case.
        func throwOffline() throws { throw AudioPlayerError.offline }

        do {
            try throwOffline()
            Issue.record("expected throw")
        } catch let error as AudioPlayerError {
            #expect(matches(error, .offline))
        } catch {
            Issue.record("error did not bridge as AudioPlayerError: \(error)")
        }
    }

    @Test func switchExhaustivenessGuard() {
        // If a case is added or removed from AudioPlayerError, this switch
        // will fail to compile — flagging the change so the matcher above
        // can be updated alongside it.
        let allCases: [AudioPlayerError] = [
            .offline,
            .downloading,
            .invalidTime,
            .missingAudioTrack,
            .loadFailed,
            .itemMissing,
            .invalidItemType,
        ]

        for error in allCases {
            switch error {
            case .offline,
                 .downloading,
                 .invalidTime,
                 .missingAudioTrack,
                 .loadFailed,
                 .itemMissing,
                 .invalidItemType:
                break
            }
        }

        #expect(allCases.count == 7)
    }
}
