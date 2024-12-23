//
//  File.swift
//
//
//  Created by Rasmus Krämer on 17.01.24.
//

import Foundation
import SPFoundation
import OSLog
import Combine

@Observable @MainActor
public final class DownloadTracker {
    let itemID: ItemIdentifier
    var currentStatus: DownloadStatus?
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        self.currentStatus = nil
    }
    
    enum DownloadStatus: Sendable, Codable {
        case missing
        case downloading
        case downloaded
    }
}
