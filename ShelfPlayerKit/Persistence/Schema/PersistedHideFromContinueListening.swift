//
//  PersistedHideFromContinueListening.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 04.05.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedHideFromContinueListening {
        #Index<PersistedHideFromContinueListening>([\.compositeKey], [\.connectionID])
        #Unique<PersistedHideFromContinueListening>([\.compositeKey])

        public private(set) var compositeKey: String
        public private(set) var connectionID: String
        public private(set) var primaryID: String

        public init(connectionID: String, primaryID: String) {
            self.compositeKey = "\(connectionID)::\(primaryID)"
            self.connectionID = connectionID
            self.primaryID = primaryID
        }
    }
}
