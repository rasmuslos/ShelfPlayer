//
//  File.swift
//
//
//  Created by Rasmus Krämer on 17.01.24.
//

import Foundation
import SPFoundation
import OSLog
import SPOffline

@Observable
public final class ItemOfflineTracker {
    let itemId: String
    
    var token: Any?
    @MainActor var _status: OfflineManager.OfflineStatus?
    
    let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "Item")
    
    @MainActor
    init(itemId: String) {
        self.itemId = itemId
        
        token = nil
        _status = nil
    }
    @MainActor
    public convenience init(_ item: Item) {
        self.init(itemId: item.id)
    }
    
    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

extension ItemOfflineTracker {
    @MainActor
    public var status: OfflineManager.OfflineStatus {
        get {
            if _status == nil {
                // logger.info("Enabled offline tracking for \(self.itemId)")
                
                token = NotificationCenter.default.addObserver(forName: PlayableItem.downloadStatusUpdatedNotification, object: nil, queue: nil) { [weak self] notification in
                    guard let self else {
                        return
                    }
                    
                    if notification.object as? String == itemId {
                        Task { @MainActor in
                            self._status = OfflineManager.shared.offlineStatus(parentId: self.itemId)
                        }
                    }
                }
                
                _status = OfflineManager.shared.offlineStatus(parentId: itemId)
            }
            
            return _status!
        }
    }
}
