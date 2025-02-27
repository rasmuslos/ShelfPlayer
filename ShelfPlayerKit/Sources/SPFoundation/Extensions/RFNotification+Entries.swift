//
//  RFNotification+Entries.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import RFNotifications

public extension RFNotification.Notification {
    static var progressEntityUpdated: Notification<(connectionID: String, primaryID: String, groupingID: String?, ProgressEntity?)> {
        .init("io.rfk.shelfPlayerKit.progressEntity.updated")
    }
    static var finalizePlaybackReporting: Notification<RFNotificationEmptyPayload> {
        .init("io.rfk.shelfPlayerKit.finalizePlaybackReporting")
    }
}
