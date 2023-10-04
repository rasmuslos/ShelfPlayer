//
//  Library.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import Foundation

struct Library {
    let id: String
    let name: String
    
    let type: MediaType
    let displayOrder: Int
    
    enum MediaType {
        case audiobooks
        case podcasts
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
        UserDefaults.standard.set("lastActiveLibraryId", forKey: id)
    }
    
    static func getLastActiveLibraryId() -> String? {
        return UserDefaults.standard.string(forKey: "lastActiveLibraryId")
    }
}
