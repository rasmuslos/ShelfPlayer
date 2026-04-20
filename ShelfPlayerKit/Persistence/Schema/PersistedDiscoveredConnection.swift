//
//  PersistedDiscoveredConnection.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 13.04.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedDiscoveredConnection {
        #Unique<PersistedDiscoveredConnection>([\.connectionID])

        public private(set) var connectionID: String

        public private(set) var host: URL
        public private(set) var user: String

        public init(connectionID: String, host: URL, user: String) {
            self.connectionID = connectionID
            self.host = host
            self.user = user
        }
    }
}
