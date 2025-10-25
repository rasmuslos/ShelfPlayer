//
//  Embassy.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 02.06.25.
//

import Foundation
import WidgetKit

public struct Embassy {
    public static func unsetWidgetIsPlaying() {
        guard let current = Defaults[.playbackInfoWidgetValue] else {
            return
        }
        
        Defaults[.playbackInfoWidgetValue] = .init(currentItemID: current.currentItemID, isDownloaded: current.isDownloaded, isPlaying: nil, listenNowItems: current.listenNowItems)
        
        WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.start")
        WidgetCenter.shared.reloadTimelines(ofKind: "io.rfk.shelfPlayer.listenNow")
    }
}
