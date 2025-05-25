//
//  SessionLoader.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.05.25.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

@MainActor @Observable
final class SessionLoader {
    let PAGE_SIZE = 20
    
    var filter: SessionFilter
    
    var page = [ItemIdentifier.ConnectionID: Int]()
    var sessions = [SessionPayload]()
    
    var isLoading = false
    var finished = [ItemIdentifier.ConnectionID: Bool]()
    
    init(filter: SessionFilter) {
        self.filter = filter
        beginLoading()
    }
    
    var isFinished: Bool {
        !finished.isEmpty && finished.reduce(true) {
            $0 && $1.1
        }
    }
    
    var totalTimeSpendListening: TimeInterval {
        sessions.reduce(0) { $0 + ($1.timeListening ?? 0) }
    }
    var mostRecent: SessionPayload? {
        sessions.max(by: { $0.startDate < $1.startDate })
    }
    
    func refresh() {
        page.removeAll()
        sessions.removeAll()
        
        isLoading = false
        finished.removeAll()
        
        beginLoading()
    }
    
    private nonisolated func beginLoading() {
        Task {
            let shouldResume = await MainActor.run {
                guard !isLoading, !isFinished else {
                    return false
                }
                
                isLoading = true
                return true
            }
            
            guard shouldResume else {
                return
            }
            
            let page = await page
            let finished = await finished
            
            let connectionIDs = await filter.connectionIDs.filter { finished[$0] != true }
            let sessions = await withTaskGroup {
                for connectionID in connectionIDs {
                    $0.addTask {
                        let page = page[connectionID] ?? 0
                        
                        do {
                            let (sessions, isFinished) = try await self.filter.sessions(page: page, pageSize: self.PAGE_SIZE, connectionID: connectionID)
                            
                            await MainActor.run {
                                self.page[connectionID] = page + 1
                                self.finished[connectionID] = isFinished
                            }
                            
                            return sessions
                        } catch {
                            await MainActor.run {
                                self.finished[connectionID] = true
                            }
                            
                            return []
                        }
                    }
                }
                
                return await $0.reduce([], +)
            }
            
            await MainActor.run {
                self.sessions += sessions
                isLoading = false
            }
            
            beginLoading()
        }
    }
    
    enum SessionFilter {
        case today
        case itemID(ItemIdentifier)
        
        #if DEBUG
        case fixture
        #endif
        
        var connectionIDs: [ItemIdentifier.ConnectionID] {
            get async {
                switch self {
                    case .today:
                        await PersistenceManager.shared.authorization.connections.map(\.key)
                    case .itemID(let itemID):
                        [itemID.connectionID]
                    #if DEBUG
                    case .fixture:
                        ["fixture"]
                    #endif
                }
            }
        }
        
        func sessions(page: Int, pageSize: Int, connectionID: ItemIdentifier.ConnectionID) async throws -> ([SessionPayload], Bool) {
            switch self {
                case .today:
                    return ([], true)
                case .itemID(let itemID):
                    let sessions = try await ABSClient[connectionID].listeningSessions(from: itemID, page: page, pageSize: pageSize)
                    return (sessions, sessions.isEmpty)
                #if DEBUG
                case .fixture:
                    return ([
                        SessionPayload.fixture,
                    ], true)
                #endif
            }
        }
    }
}
