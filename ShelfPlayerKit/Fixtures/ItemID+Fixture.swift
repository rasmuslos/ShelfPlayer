//
//  ItemID+Fixture.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 30.12.24.
//



import Foundation

#if DEBUG
public extension ItemIdentifier {
    static var fixture: ItemIdentifier {
        .init(primaryID: "fixture", groupingID: nil, libraryID: "fixture", connectionID: "fixture", type: .audiobook)
    }
}
#endif
