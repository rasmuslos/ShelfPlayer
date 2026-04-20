//
//  ConfigureableUpNextStrategy.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.05.25.
//

import Foundation

public enum ConfigureableUpNextStrategy: String, Sendable, Hashable, CaseIterable, Equatable, Identifiable, Codable {
    case `default`
    case listenNow
    case disabled

    public var id: String {
        rawValue
    }
}
