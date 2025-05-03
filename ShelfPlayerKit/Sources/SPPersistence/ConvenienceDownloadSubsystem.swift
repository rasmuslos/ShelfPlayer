//
//  ConvenienceDownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 03.05.25.
//

import Foundation
import SPFoundation

extension PersistenceManager {
    public struct ConvenienceDownloadSubsystem {
        @MainActor var isRunning = false
    }
}
