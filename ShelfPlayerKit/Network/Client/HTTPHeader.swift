//
//  HTTPHeader.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 28.07.25.
//

import Foundation

public struct HTTPHeader: Sendable, Codable, Hashable {
    public var key: String
    public var value: String
    
    public init(key: String, value: String) {
        self.key = key
        self.value = value
    }
}
