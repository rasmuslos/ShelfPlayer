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
    var _status: OfflineManager.OfflineStatus?
    
    let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "Item")
    
    init(itemId: String) {
        self.itemId = itemId
        
        token = nil
        _status = nil
    }
    
    deinit {
        if let token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

extension ItemOfflineTracker {
    public var status: OfflineManager.OfflineStatus {
        get {
            if _status == nil {
                logger.info("Enabled offline tracking for \(self.itemId)")
                
                token = NotificationCenter.default.addObserver(forName: PlayableItem.downloadStatusUpdatedNotification, object: nil, queue: nil) { [weak self] notification in
                    if notification.object as? String == self?.itemId {
                        self?._status = self?.checkOfflineStatus()
                    }
                }
                
                _status = checkOfflineStatus()
            }
            
            return _status!
        }
    }
    
    private func checkOfflineStatus() -> OfflineManager.OfflineStatus {
        return OfflineManager.shared.getOfflineStatus(parentId: itemId)
    }
}
