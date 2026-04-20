//
//  Library+Fixture.swift
//  ShelfPlayerKit
//

import Foundation

#if DEBUG
public extension Library {
    static var fixture: Library {
        .init(id: "fixture", connectionID: "fixture", name: "Fixture", type: .audiobooks, index: -1)
    }
}
#endif
