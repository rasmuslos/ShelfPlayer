//
//  RFNotification+Entries.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 23.12.24.
//

import RFNotifications

public extension RFNotification.Notification {
    static var progressEntityUpdated: Notification<ProgressEntity> {
        .init("io.rfk.shelfPlayerKit.progressEntity.updated")
    }
}
