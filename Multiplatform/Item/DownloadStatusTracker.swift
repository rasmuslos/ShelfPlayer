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
        
    private nonisolated func load() {
        Task {
            let status = await DownloadTrackerCache.shared.resolve(itemID)
            
            await MainActor.withAnimation {
                self.status = status
            }
        }
    }
}

actor DownloadTrackerCache: Sendable {
    private var cache = [ItemIdentifier: DownloadStatus]()
    
    fileprivate func resolve(_ itemID: ItemIdentifier) async -> DownloadStatus {
        if let cached = cache[itemID] {
            return cached
        }
        
        let status = await PersistenceManager.shared.download.status(of: itemID)
        cache[itemID] = status
        
        return status
    }
    func invalidate() {
        cache.removeAll()
    }
    
    nonisolated static let shared = DownloadTrackerCache()
}

