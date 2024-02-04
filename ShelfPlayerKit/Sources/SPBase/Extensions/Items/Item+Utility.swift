//
//  File.swift
//  
//
//  Created by Rasmus Krämer on 04.02.24.
//

import Foundation

extension Item: Equatable {
    public static func == (lhs: Item, rhs: Item) -> Bool {
        lhs.id == rhs.id
    }
}

extension Item: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension Item: Comparable {
    public static func < (lhs: Item, rhs: Item) -> Bool {
        lhs.name < rhs.name
    }
}

public extension Item {
    var sortName: String {
        get {
            var sortName = name.lowercased()
            
            if sortName.starts(with: "a ") {
                sortName = String(sortName.dropFirst(2))
            }
            if sortName.starts(with: "the ") {
                sortName = String(sortName.dropFirst(4))
            }
            
            return sortName
        }
    }
}
