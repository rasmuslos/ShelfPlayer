//
//  ItemSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 27.02.25.
//

import Foundation
import SwiftData
import SPFoundation

extension PersistenceManager {
    public final class ItemSubsystem: Sendable {
    }
}

public extension PersistenceManager.ItemSubsystem {
    func playbackRate(for itemID: ItemIdentifier) async -> Percentage? {
        await PersistenceManager.shared.keyValue[.playbackRate(for: itemID)]
    }
    func setPlaybackRate(_ rate: Percentage, for itemID: ItemIdentifier) async throws {
        try await PersistenceManager.shared.keyValue.set(.playbackRate(for: itemID), rate)
    }
}

private extension PersistenceManager.KeyValueSubsystem.Key {
    static func playbackRate(for itemID: ItemIdentifier) -> Key<Percentage> {
        .init("playbackRate-\(itemID)")
    }
}
