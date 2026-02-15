//
//  DownloadStatusTracker.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 24.02.25.
//

import SwiftUI
import ShelfPlayback

@Observable @MainActor
final class DownloadStatusTracker {
    let itemID: ItemIdentifier
    var status: DownloadStatus?
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        
        load()
        
        RFNotification[.downloadStatusChanged].subscribe { [weak self] in
            guard let (itemID, status) = $0 else {
                self?.load()
                return
            }
            
            guard self?.itemID == itemID else {
                return
            }
            
            withAnimation {
                self?.status = status
            }
        }
    }
        
    private func load() {
        Task {
            let status = await PersistenceManager.shared.download.status(of: itemID)
            
            withAnimation {
                self.status = status
            }
        }
    }
}
