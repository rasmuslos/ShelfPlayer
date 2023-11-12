//
//  Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

struct Library: Identifiable {
    let id: String
    let name: String
    
    let type: MediaType
    let displayOrder: Int
    
    enum MediaType {
        case audiobooks
        case podcasts
    }
}

@Observable
class AvailableLibraries {
    let libraries: [Library]
    
    init(libraries: [Library]) {
        self.libraries = libraries
    }
}

// MARK: Comparable

extension Library: Comparable {
    static func < (lhs: Library, rhs: Library) -> Bool {
        lhs.displayOrder < rhs.displayOrder
    }
}

// MARK: last active library

extension Library {
    func setAsLastActiveLibrary() {
        UserDefaults.standard.set(id, forKey: "lastActiveLibraryId")
    }
    
    static func getLastActiveLibraryId() -> String? {
        UserDefaults.standard.string(forKey: "lastActiveLibraryId")
    }
}

// MARK: Notifications

extension Library {
    static let libraryChangedNotification = NSNotification.Name("io.rfk.library.changed")
}
