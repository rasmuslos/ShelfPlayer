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
    static var connectionsChanged: Notification<[ItemIdentifier.ConnectionID: PersistenceManager.AuthorizationSubsystem.Connection]> {
        .init("io.rfk.ShelfPlayer.connectionsChanged")
    }
    
    static var downloadStatusChanged: Notification<(itemID: ItemIdentifier, status: PersistenceManager.DownloadSubsystem.DownloadStatus)> {
        .init("io.rfk.shelfPlayerKit.progressEntity.updated")
    }
    static func downloadProgressChanged(_ itemID: ItemIdentifier) -> Notification<(assetID: UUID, weight: Percentage, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)> {
        .init("io.rfk.shelfPlayerKit.progress.updated_\(itemID)")
    }
}
