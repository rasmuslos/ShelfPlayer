//
//  DownloadSubsystem.swift
//  ShelfPlayerKit
//
//  Created by Rasmus Krämer on 25.12.24.
//

import Foundation
import SwiftData
import RFNetwork
import RFNotifications
import SPFoundation
import SPNetwork

extension PersistenceManager {
    @ModelActor
    public final actor DownloadSubsystem {
        public func download(_ itemID: ItemIdentifier) async throws {
            guard itemID.type == .audiobook || itemID.type == .episode else {
                throw PersistenceError.unsupportedDownloadItemType
            }
            
            let (item, audioTracks, chapters, supplementaryPDFs) = try await ABSClient[itemID.connectionID].playableItem(itemID: itemID)
        }
    }
}
