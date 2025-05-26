//
//  PersistedKeyValueEntity.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 28.11.24.
//

import Foundation
import SwiftData
import SPFoundation

extension SchemaV2 {
    @Model
    final class PersistedKeyValueEntity {
        #Index<PersistedKeyValueEntity>([\.id], [\.key], [\.cluster])
        #Unique<PersistedKeyValueEntity>([\.id], [\.key])
        
        private(set) var id: UUID
        
        private(set) var key: String
        private(set) var cluster: String
        
        var value: Data
        
        init(key: String, cluster: String, value: Data, isCachePurgeable: Bool) {
            id = UUID()
            
            self.key = key
            self.cluster = cluster
            self.value = value
            self.isCachePurgeable = isCachePurgeable
        }
        
        private(set) var isCachePurgeable: Bool
    }
}
