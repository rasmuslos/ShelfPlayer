//
//  WidgetManager.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 29.05.25.
//

import Foundation
import WidgetKit
import Defaults
import ShelfPlayerKit

struct WidgetManager {
    static func setupObservers() {
        RFNotification[.timeSpendListeningChanged].subscribe { minutes in
            Defaults[.listenedTodayWidgetValue] = ListenedTodayPayload(total: minutes, updated: .now)
            WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenedToday")
        }
        
        Task {
            for await _ in Defaults.updates(.listenTimeTarget) {
                WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenedToday")
            }
        }
    }
}
