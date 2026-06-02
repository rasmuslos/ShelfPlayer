//
//  Channel+Fixture.swift
//  ShelfPlayerKit
//

import Foundation

#if DEBUG
public extension Channel {
    static let fixture = Channel(
        id: Channel.convertNameToID("Deutschlandfunk Kultur", libraryID: "fixture", connectionID: "fixture"),
        name: "Deutschlandfunk Kultur",
        podcasts: .init(repeating: .fixture, count: 5))
}
#endif
