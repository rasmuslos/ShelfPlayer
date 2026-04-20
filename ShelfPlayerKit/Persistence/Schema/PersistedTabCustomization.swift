//
//  PersistedTabCustomization.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedTabCustomization {
        #Index<PersistedTabCustomization>([\.compositeKey])
        #Unique<PersistedTabCustomization>([\.compositeKey])

        public private(set) var compositeKey: String
        public private(set) var libraryID: String
        public private(set) var scope: String
        public var tabsData: Data

        public init(libraryID: String, scope: String, tabsData: Data) {
            self.compositeKey = "\(libraryID)::\(scope)"
            self.libraryID = libraryID
            self.scope = scope
            self.tabsData = tabsData
        }
    }
}
