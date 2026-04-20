//
//  Embassy.swift
//  ShelfPlayerKit
//

import Foundation
import WidgetKit

public struct Embassy {
    public static func unsetWidgetIsPlaying() {
        guard let current = AppSettings.shared.playbackInfoWidgetValue else {
            return
        }

        AppSettings.shared.playbackInfoWidgetValue = .init(currentItemID: current.currentItemID, isPlaying: nil)

        WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.start")
        WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
    }
}
