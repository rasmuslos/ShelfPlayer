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
    
    init(id: String, name: String, type: String, displayOrder: Int) {
        self.id = id
        self.name = name
        self.type = type == "book" ? .audiobooks : type == "podcast" ? .podcasts : nil
        self.displayOrder = displayOrder
    }
    
    init(id: String, name: String, type: MediaType, displayOrder: Int) {
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

@Observable
public class AvailableLibraries {
    public let libraries: [Library]
    
    public init(libraries: [Library]) {
        self.libraries = libraries
    }
}

// MARK: Comparable

extension Library: Comparable {
    public static func < (lhs: Library, rhs: Library) -> Bool {
        lhs.displayOrder < rhs.displayOrder
    }
}

// MARK: last active library

extension Library {
    public func setAsLastActiveLibrary() {
        UserDefaults.standard.set(id, forKey: "lastActiveLibraryId")
    }
    
    public static func getLastActiveLibraryId() -> String? {
        UserDefaults.standard.string(forKey: "lastActiveLibraryId")
    }
}

// MARK: Notifications

extension Library {
    public static let libraryChangedNotification = NSNotification.Name("io.rfk.library.changed")
}
