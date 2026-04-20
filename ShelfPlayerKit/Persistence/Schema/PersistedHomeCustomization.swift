//
//  PersistedHomeCustomization.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 19.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedHomeCustomization {
        #Index<PersistedHomeCustomization>([\.scopeKey])
        #Unique<PersistedHomeCustomization>([\.scopeKey])

        public private(set) var scopeKey: String
        public var sectionsData: Data

        public init(scopeKey: String, sectionsData: Data) {
            self.scopeKey = scopeKey
            self.sectionsData = sectionsData
        }
    }
}
