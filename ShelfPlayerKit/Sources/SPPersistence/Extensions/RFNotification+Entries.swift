//
//  RFNotification+Entries.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 14.02.25.
//

import Foundation
import RFNotifications
import SPFoundation

public extension RFNotification.Notification {
    static var downloadStatusChanged: Notification<(itemID: ItemIdentifier, PersistenceManager.DownloadSubsystem.DownloadStatus)> {
        .init("io.rfk.shelfPlayerKit.progressEntity.updated")
    }
}
