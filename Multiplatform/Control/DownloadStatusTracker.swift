//
//  DownloadStatusTracker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.02.25.
//

import SwiftUI
import ShelfPlayerKit

@Observable @MainActor
final class DownloadStatusTracker {
    let itemID: ItemIdentifier
    var status: PersistenceManager.DownloadSubsystem.DownloadStatus?
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        
        load()
        
        RFNotification[.downloadStatusChanged].subscribe { [weak self] (itemID, status) in
            guard self?.itemID == itemID else {
                return
            }
            
            withAnimation {
                self?.status = status
            }
        }
    }
    
    private nonisolated func load() {
        Task {
            let status = await PersistenceManager.shared.download.status(of: itemID)
            
            await MainActor.withAnimation {
                self.status = status
            }
        }
    }
}
