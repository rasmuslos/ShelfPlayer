//
//  ItemID+Fixture.swift
//  ShelfPlayerKit
//

import Foundation

#if DEBUG
public extension ItemIdentifier {
    static var fixture: ItemIdentifier {
        .init(primaryID: "fixture", groupingID: nil, libraryID: "fixture", connectionID: "fixture", type: .audiobook)
    }
}
#endif
