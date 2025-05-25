//
//  RFNotification+Entries.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 14.02.25.
//

import Foundation
import RFNotifications
import SPFoundation

public extension RFNotification.IsolatedNotification {
    static var connectionsChanged: IsolatedNotification<[ItemIdentifier.ConnectionID: PersistenceManager.AuthorizationSubsystem.Connection]> {
        .init("io.rfk.shelfPlayerKit.connectionsChanged")
    }
    static var removeConnection: IsolatedNotification<ItemIdentifier.ConnectionID> {
        .init("io.rfk.shelfPlayerKit.removeConnection")
    }
    
    static var progressEntityUpdated: IsolatedNotification<(connectionID: String, primaryID: String, groupingID: String?, ProgressEntity?)> {
        .init("io.rfk.shelfPlayerKit.progressEntity.updated")
    }
    static var invalidateProgressEntities: IsolatedNotification<String?> {
        .init("io.rfk.shelfPlayerKit.progressEntity.invalidate")
    }
    
    static var downloadStatusChanged: IsolatedNotification<(itemID: ItemIdentifier, status: PersistenceManager.DownloadSubsystem.DownloadStatus)?> {
        .init("io.rfk.shelfPlayerKit.downloadStatus.updated")
    }
    static func downloadProgressChanged(_ itemID: ItemIdentifier) -> IsolatedNotification<(assetID: UUID, weight: Percentage, bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64)> {
        .init("io.rfk.shelfPlayerKit.progress.updated_\(itemID.description)")
    }
    
    static var bookmarksChanged: IsolatedNotification<ItemIdentifier> {
        .init("io.rfk.shelfPlayerKit.bookmarksChanged")
    }
}
