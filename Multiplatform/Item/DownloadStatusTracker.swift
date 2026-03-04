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
            let status = await DownloadStatusCache.shared.status(for: itemID)
            
            withAnimation {
                self.status = status
            }
        }
    }
}

private actor DownloadStatusCache: Sendable {
    var cached = [ItemIdentifier: Task<DownloadStatus, Never>]()
    
    private init() {
        RFNotification[.downloadStatusChanged].subscribe { [weak self] payload in
            Task {
                await self?.invalidate(payload: payload)
            }
        }
    }
    
    func status(for itemID: ItemIdentifier) async -> DownloadStatus {
        if cached[itemID] == nil {
            cached[itemID] = Task.detached {
                await PersistenceManager.shared.download.status(of: itemID)
            }
        }
        
        return await cached[itemID]!.value
    }
    
    private func invalidate(payload: (itemID: ItemIdentifier, status: DownloadStatus)?) {
        guard let payload else {
            cached.removeAll()
            return
        }
        
        cached[payload.itemID] = Task {
            payload.status
        }
    }
    
    nonisolated static let shared = DownloadStatusCache()
}
