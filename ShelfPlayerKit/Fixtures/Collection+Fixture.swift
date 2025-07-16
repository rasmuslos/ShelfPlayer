//
//  Collection+Fixture.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 16.07.25.
//

import Foundation

#if DEBUG
public extension ItemCollection {
    static let collectionFixture = ItemCollection(id: .init(primaryID: "fixture", groupingID: nil, libraryID: "fixture", connectionID: "fixture", type: .collection), name: "Fixture", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.", addedAt: .now, items: .init(repeating: Audiobook.fixture, count: 7))
    static let playlistFixture = ItemCollection(id: .init(primaryID: "fixture", groupingID: nil, libraryID: "fixture", connectionID: "fixture", type: .collection), name: "Fixture", description: "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet.", addedAt: .now, items: .init(repeating: Episode.fixture, count: 7))
}
#endif
