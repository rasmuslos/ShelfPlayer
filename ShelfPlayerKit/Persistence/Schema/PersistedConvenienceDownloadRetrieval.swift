//
//  PersistedConvenienceDownloadRetrieval.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 04.05.26.
//

import Foundation
import SwiftData

extension ShelfPlayerSchema {
    @Model
    public final class PersistedConvenienceDownloadRetrieval {
        #Index<PersistedConvenienceDownloadRetrieval>([\.configurationID])
        #Unique<PersistedConvenienceDownloadRetrieval>([\.configurationID])

        public private(set) var configurationID: String
        public var retrievalData: Data

        public init(configurationID: String, retrievalData: Data) {
            self.configurationID = configurationID
            self.retrievalData = retrievalData
        }
    }
}
