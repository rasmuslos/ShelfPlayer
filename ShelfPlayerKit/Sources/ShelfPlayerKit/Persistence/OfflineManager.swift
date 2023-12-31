//
//  OfflineManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData
import OSLog

public struct OfflineManager {
    let logger = Logger(subsystem: "io.rfk.audiobooks", category: "OfflineProgress")
    
    private init() {
    }
}

// MARK: Singleton
extension OfflineManager {
    public static let shared = OfflineManager()
}
