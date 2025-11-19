//
//  Session+Fixture.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 20.11.25.
//

#if DEBUG
public extension SessionPayload {
    static let fixture = SessionPayload(id: "fixture",
                                        userId: "fixture",
                                        libraryId: "fixture",
                                        libraryItemId: "fixture",
                                        episodeId: "fixture",
                                        mediaType: "episode",
                                        mediaMetadata: nil,
                                        chapters: nil,
                                        displayTitle: nil,
                                        displayAuthor: nil,
                                        coverPath: nil,
                                        duration: nil,
                                        playMethod: 0,
                                        mediaPlayer: "ShelfPlayer",
                                        deviceInfo: nil,
                                        date: "2022-11-13",
                                        dayOfWeek: "Sunday",
                                        serverVersion: "1.2.3",
                                        timeListening: 600,
                                        startTime: 0,
                                        currentTime: 600,
                                        startedAt: 1668330137087.0,
                                        updatedAt: 1668330152157.0)
}
#endif
