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
    static func timeListenedTodayChanged(_ value: Int) {
        Defaults[.listenedTodayWidgetValue] = ListenedTodayPayload(total: value, updated: .now)
        WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenedToday")
    }
}
