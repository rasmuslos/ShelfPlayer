//
//  Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

public struct Library: Identifiable {
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
    
    internal init(id: String, name: String, type: MediaType, displayOrder: Int) {
        self.id = id
        self.name = name
        self.type = type
        self.displayOrder = displayOrder
    }
    
    public enum MediaType {
        case audiobooks
        case podcasts
    }
}

extension Library: Comparable {
    public static func < (lhs: Library, rhs: Library) -> Bool {
        lhs.displayOrder < rhs.displayOrder
    }
}

public extension Library {
    static let changeLibraryNotification = NSNotification.Name("io.rfk.shelfplayer.library.change")
}
