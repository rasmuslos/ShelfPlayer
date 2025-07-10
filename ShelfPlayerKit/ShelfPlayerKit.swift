//
//  ShelfPlayerKit.swift
//  
//
//  Created by Rasmus Krämer on 22.06.24.
//

import Foundation
import OSLog
import AppIntents

@_exported import Defaults
@_exported import DefaultsMacros

@_exported import RFVisuals
@_exported import RFNetwork
@_exported import RFNotifications

public struct ShelfPlayerKit {
    public static let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ShelfPlayerKit")
}

public struct ShelfPlayerKitPackage: AppIntentsPackage {}
