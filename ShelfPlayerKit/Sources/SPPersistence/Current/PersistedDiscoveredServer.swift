//
//  PersistedDiscoveredServer.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import Foundation
import SwiftData

extension SchemaV2 {
    @Model
    final class PersistedDiscoveredServer {
        @Attribute(.unique)
        private(set) var serverID: String
        
        private(set) var host: URL
        private(set) var user: String
        
        init(serverID: String, host: URL, user: String) {
            self.serverID = serverID
            self.host = host
            self.user = user
        }
    }
}
