//
//  PersistedDiscoveredConnection.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import SwiftData

extension SchemaV2 {
    @Model
    final class PersistedDiscoveredConnection {
        #Unique<PersistedDiscoveredConnection>([\.connectionID])
        
        private(set) var connectionID: String
        
        private(set) var host: URL
        private(set) var user: String
        
        init(connectionID: String, host: URL, user: String) {
            self.connectionID = connectionID
            self.host = host
            self.user = user
        }
    }
}
