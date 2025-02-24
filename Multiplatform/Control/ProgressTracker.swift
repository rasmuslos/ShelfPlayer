//
//  ProgressTracker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.02.25.
//

import SwiftUI
import ShelfPlayerKit

@Observable @MainActor
final class ProgressTracker {
    let itemID: ItemIdentifier
    var entity: ProgressEntity.UpdatingProgressEntity?
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        load()
    }
    
    nonisolated func load() {
        Task {
            let entity = await PersistenceManager.shared.progress[itemID].updating
            
            await MainActor.withAnimation {
                self.entity = entity
            }
        }
    }
}
