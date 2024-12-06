//
//  PersistedKeyValueEntity.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 28.11.24.
//

import Foundation
import SwiftData

extension SchemaV2 {
    final class PersistedKeyValueEntity {
        @Attribute(.unique)
        private(set) var key: String
        var value: Data
        
        init(key: String, value: Data) {
            self.key = key
            self.value = value
        }
    }
}
