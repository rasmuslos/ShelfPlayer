//
//  Chapter.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 26.11.24.
//

import Foundation

public struct Chapter {
    public let id: Int
    public let startOffset: TimeInterval
    public let endOffset: TimeInterval
    public let title: String
    
    public init(id: Int, startOffset: TimeInterval, endOffset: TimeInterval, title: String) {
        self.id = id
        self.startOffset = startOffset
        self.endOffset = endOffset
        self.title = title
    }
    
    public var duration: TimeInterval {
        endOffset - startOffset
    }
}

extension Chapter: Sendable {}
extension Chapter: Comparable {
    public static func <(lhs: Self, rhs: Self) -> Bool {
        lhs.startOffset < rhs.startOffset
    }
}
extension Chapter: Identifiable {}
