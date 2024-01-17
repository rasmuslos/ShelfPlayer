//
//  File.swift
//
//
//  Created by Rasmus Krämer on 17.01.24.
//

import Foundation
import SPBaseKit
import OSLog
import SPOfflineKit

extension PlayableItem {
    public var offlineTracker: ItemOfflineTracker {
        .init(itemId: self.id)
    }
}

@Observable
public class ItemOfflineTracker {
    let itemId: String
    
    var _status: OfflineStatus? = nil
    var token: Any? = nil
    
    let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "Item")
    
    init(itemId: String) {
        self.itemId = itemId
    }
    
    deinit {
        if let token = token {
            NotificationCenter.default.removeObserver(token)
        }
    }
}

extension ItemOfflineTracker {
    @MainActor
    public var status: OfflineStatus {
        get {
            if _status == nil {
                logger.info("Enabled offline tracking for \(self.itemId)")
                
                token = NotificationCenter.default.addObserver(forName: PlayableItem.downloadStatusUpdatedNotification, object: nil, queue: nil) { [weak self] notification in
                    if notification.object as? String == self?.itemId {
                        Task.detached { [self] in
                            self?._status = await self?.checkOfflineStatus()
                        }
                    }
                }
                
                _status = checkOfflineStatus()
            }
            
            return _status!
        }
    }
    
    @MainActor
    func checkOfflineStatus() -> OfflineStatus {
        return OfflineManager.shared.getOfflineStatus(parentId: itemId)
    }
}

// MARK: Helper

extension ItemOfflineTracker {
    public enum OfflineStatus: Int {
        case none = 0
        case working = 1
        case downloaded = 2
    }
}
