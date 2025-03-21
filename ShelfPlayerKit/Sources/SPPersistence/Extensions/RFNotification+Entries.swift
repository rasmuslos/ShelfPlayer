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
        .init("io.rfk.shelfPlayerKit.connectionsChanged")
    }
    
    static var progressEntityUpdated: Notification<(connectionID: String, primaryID: String, groupingID: String?, ProgressEntity?)> {
        .init("io.rfk.shelfPlayerKit.progressEntity.updated")
    }
    static var invalidateProgressEntities: Notification<String?> {
        .init("io.rfk.shelfPlayerKit.progressEntity.invalidate")
    }
    
    static var downloadStatusChanged: Notification<(itemID: ItemIdentifier, status: PersistenceManager.DownloadSubsystem.DownloadStatus)> {
        .init("io.rfk.shelfPlayerKit.downloadStatus.updated")
    }
    static func downloadProgressChanged(_ itemID: ItemIdentifier) -> Notification<(assetID: UUID, weight: Percentage, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)> {
        .init("io.rfk.shelfPlayerKit.progress.updated_\(itemID)")
    }
    
    static var bookmarksChanged: Notification<ItemIdentifier> {
        .init("io.rfk.shelfPlayerKit.bookmarksChanged")
    }
}
