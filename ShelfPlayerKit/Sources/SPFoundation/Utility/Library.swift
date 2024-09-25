//
//  Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation
import Defaults

public struct Library: Identifiable, Hashable, Codable, Defaults.Serializable {
    public let id: String
    public let name: String
    
    public let type: MediaType!
    public let displayOrder: Int
    
    public init(id: String, name: String, type: String, displayOrder: Int) {
        self.id = id
        self.name = name
        self.type = type == "book" ? .audiobooks : type == "podcast" ? .podcasts : nil
        self.displayOrder = displayOrder
    }
    
    public init(id: String, name: String, type: MediaType, displayOrder: Int) {
        self.id = id
        self.name = name
        self.type = type
        self.displayOrder = displayOrder
    }
    
    public enum MediaType: Int, Hashable, Codable, Defaults.Serializable {
        case audiobooks = 1
        case podcasts = 2
        
        case offline = 0
    }
}

extension Library: Comparable {
    public static func < (lhs: Library, rhs: Library) -> Bool {
        lhs.displayOrder < rhs.displayOrder
    }
}
