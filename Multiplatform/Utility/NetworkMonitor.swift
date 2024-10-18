//
//  NetworkMonitor.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 31.08.24.
//

import Foundation
import Network
import ShelfPlayerKit

internal struct NetworkMonitor {
    private static var didInit = false
    private static let pathMonitor = NWPathMonitor()
    
    static func start(callback: @escaping () -> Void) {
        pathMonitor.pathUpdateHandler = { networkPath in
            guard networkPath.status == .satisfied, AudiobookshelfClient.shared.authorized else {
                return
            }
            
            guard self.didInit else {
                self.didInit = true
                return
            }
            
            guard OfflineManager.shared.hasCachedChanges else {
                return
            }
            
            Task {
                let status = try? await AudiobookshelfClient.shared.status()
                
                guard status != nil else {
                    return
                }
                
                callback()
            }
        }
        
        pathMonitor.start(queue: DispatchQueue.global(qos: .userInitiated))
    }
    
    static var isRouteLimited: Bool {
        pathMonitor.currentPath.isExpensive || pathMonitor.currentPath.isConstrained
    }
}
