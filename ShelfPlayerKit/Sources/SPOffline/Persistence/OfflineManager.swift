//
//  OfflineManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import OSLog

public struct OfflineManager {
    public let logger = Logger(subsystem: "io.rfk.shelfplayer", category: "OfflineProgress")
}

public extension OfflineManager {
    static let shared = OfflineManager()
}
