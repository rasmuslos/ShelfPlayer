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
import SPOffline

@Observable
public final class ItemOfflineTracker {
    let itemID: ItemIdentifier
    
    @ObservationIgnored var token: AnyCancellable?
    @MainActor var _status: OfflineManager.OfflineStatus?
    
    @ObservationIgnored let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "Item")
    
    @MainActor
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        
        token = nil
        _status = nil
    }
    @MainActor
    public convenience init(_ item: Item) {
        self.init(itemID: item.id)
    }
}

extension ItemOfflineTracker {
    @MainActor
    public var status: OfflineManager.OfflineStatus {
        get {
            if _status == nil {
                token = PlayableItem.downloadStatusUpdatedPublisher.sink { [weak self] in
                    guard let self, $0 == itemID else {
                        return
                    }
                    
                    Task { @MainActor in
                        self._status = OfflineManager.shared.offlineStatus(parentId: self.itemID.offlineID)
                    }
                }
                
                _status = OfflineManager.shared.offlineStatus(parentId: self.itemID.offlineID)
            }
            
            return _status!
        }
    }
}
