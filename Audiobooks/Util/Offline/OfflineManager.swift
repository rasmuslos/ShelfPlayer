//
//  OfflineManager.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import Foundation
import SwiftData

struct OfflineManager {
    private init() {
    }
}

// MARK: Singleton
extension OfflineManager {
    static let shared = OfflineManager()
}
