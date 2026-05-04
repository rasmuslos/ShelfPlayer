//
//  PersistedConvenienceDownloadAssociation.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 04.05.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedConvenienceDownloadAssociation {
        #Index<PersistedConvenienceDownloadAssociation>([\.itemID])
        #Unique<PersistedConvenienceDownloadAssociation>([\.itemID])

        public private(set) var itemID: String
        public var configurationIDsData: Data

        public init(itemID: String, configurationIDsData: Data) {
            self.itemID = itemID
            self.configurationIDsData = configurationIDsData
        }
    }
}
