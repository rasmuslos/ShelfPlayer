//
//  ItemSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.02.25.
//

import Foundation
import SwiftUI
import SwiftData
import OSLog
import SPFoundation
import RFVisuals

extension PersistenceManager {
    public final class ItemSubsystem: Sendable {
        let logger = Logger(subsystem: "io.rfk.shelfPlayerKit", category: "ItemSubsystem")
    }
}

public extension PersistenceManager.ItemSubsystem {
    func playbackRate(for itemID: ItemIdentifier) async -> Percentage? {
        await PersistenceManager.shared.keyValue[.playbackRate(for: itemID)]
    }
    func setPlaybackRate(_ rate: Percentage, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.playbackRate(for: itemID), rate)
    }
    func allowUpNextQueueGeneration(for itemID: ItemIdentifier) async -> Bool {
        await PersistenceManager.shared.keyValue[.allowUpNextQueueGeneration(for: itemID)] ?? true
    }
    func setAllowUpNextQueueGeneration(_ allow: Bool, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.allowUpNextQueueGeneration(for: itemID), allow)
    }
    
    func dominantColor(of itemID: ItemIdentifier) async -> Color? {
        if let stored = await PersistenceManager.shared.keyValue[.dominantColor(of: itemID)] {
            let components = stored.split(separator: ":").map { Double($0) ?? 0 }
            return Color(red: components[0], green: components[1], blue: components[2])
        }
        
        guard let image = await itemID.platformCover(size: .small), let colors = try? await RFKVisuals.extractDominantColors(4, image: image) else {
            return nil
        }
        
        let filtered = RFKVisuals.brightnessExtremeFilter(colors.map { $0.color }, threshold: 0.1)
        
        guard let result = RFKVisuals.determineMostSaturated(filtered) else {
            return nil
        }
        
        let resolved = result.resolve(in: .init())
        let stored = "\(resolved.red):\(resolved.green):\(resolved.blue)"
        
        do {
            try await PersistenceManager.shared.keyValue.set(.dominantColor(of: itemID), stored)
        } catch {
            logger.error("Failed to store color for \(itemID): \(error)")
        }
        
        return result
    }
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    // Contains the stored rate for playable items (audiobook, episode) and overrides for others (author, series,  podcast)
    static func playbackRate(for itemID: ItemIdentifier) -> Key<Percentage> {
        let isPurgeable: Bool
        
        switch itemID.type {
        case .audiobook, .episode:
            isPurgeable = true
        case .author, .narrator, .series, .podcast:
            isPurgeable = false
        }
        
        return Key(identifier: "playbackRate-\(itemID)", cluster: "playbackRates", isCachePurgeable: isPurgeable)
    }
    
    static func allowUpNextQueueGeneration(for itemID: ItemIdentifier) -> Key<Bool> {
        Key(identifier: "allowUpNextQueueGeneration-\(itemID)", cluster: "allowUpNextQueueGeneration", isCachePurgeable: false)
    }
    
    static func dominantColor(of itemID: ItemIdentifier) -> Key<String> {
        Key(identifier: "dominantColor-\(itemID)", cluster: "dominantColors", isCachePurgeable: true)
    }
}
