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
public final class DownloadStatusTracker {
    let itemID: ItemIdentifier
    
    var status: OfflineManager.OfflineStatus
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        status = .none
    }
    public convenience init(_ item: Item) {
        self.init(itemID: item.id)
    }
}
