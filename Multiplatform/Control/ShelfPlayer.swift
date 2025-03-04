//
//  ShelfPlayer.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 04.03.25.
//

import Foundation
import ShelfPlayerKit

struct ShelfPlayer {
    static func initializeHook() {
        Task {
            await PersistenceManager.shared.download.invalidateActiveDownloads()
        }
    }
    
    static func updateUIHook() {
        PersistenceManager.shared.download.scheduleUpdateTask()
        RFNotification[.invalidateProgressEntities].send(nil)
    }
}
