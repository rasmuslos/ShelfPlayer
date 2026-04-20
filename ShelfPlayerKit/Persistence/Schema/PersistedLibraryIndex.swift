//
//  PersistedLibraryIndex.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedLibraryIndex {
        #Index<PersistedLibraryIndex>([\.libraryKey])
        #Unique<PersistedLibraryIndex>([\.libraryKey])

        public private(set) var libraryKey: String
        public var page: Int
        public var totalItemCount: Int?
        public var startDate: Date?
        public var endDate: Date?
        public var indexedIDsData: Data?

        public init(libraryKey: String, page: Int, totalItemCount: Int? = nil, startDate: Date? = nil, endDate: Date? = nil, indexedIDsData: Data? = nil) {
            self.libraryKey = libraryKey
            self.page = page
            self.totalItemCount = totalItemCount
            self.startDate = startDate
            self.endDate = endDate
            self.indexedIDsData = indexedIDsData
        }
    }
}
