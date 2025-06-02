//
//  SessionLoader.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 25.05.25.
//

import Foundation
import SwiftUI
import RFNotifications
import ShelfPlayerKit

@MainActor @Observable
public final class SessionLoader {
    private let PAGE_SIZE = 20
    
    private let filter: SessionFilter
    private let callback: (() -> Void)?
    
    private var page = [ItemIdentifier.ConnectionID: Int]()
    public private(set) var sessions = [SessionPayload]()
    
    public private(set) var isLoading = false
    private var finished = [ItemIdentifier.ConnectionID: Bool]()
    
    public init(filter: SessionFilter, callback: (() -> Void)? = nil) {
        self.filter = filter
        self.callback = callback
        
        beginLoading()
        
        RFNotification[.synchronizedPlaybackSessions].subscribe { [weak self] in
            self?.refresh()
        }
    }
    
    public var isFinished: Bool {
        !finished.isEmpty && finished.reduce(true) {
            $0 && $1.1
        }
    }
    
    public var totalTimeSpendListening: TimeInterval {
        sessions.reduce(0) { $0 + ($1.timeListening ?? 0) }
    }
    public var mostRecent: SessionPayload? {
        sessions.max(by: { $0.startDate < $1.startDate })
    }
    
    public func refresh() {
        guard !isLoading else {
            return
        }
        
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
            
            guard !connectionIDs.isEmpty else {
                await MainActor.run {
                    isLoading = false
                }
                
                return
            }
            
            let existing = await self.sessions.map(\.id)
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
            }.filter { !existing.contains($0.id) }
            
            await MainActor.run {
                self.sessions += sessions
                isLoading = false
                
                if isFinished {
                    callback?()
                }
                
                print(totalTimeSpendListening)
            }
            
            beginLoading()
        }
    }
    
    public enum SessionFilter: Sendable {
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
                    let startOfDay = Calendar.current.startOfDay(for: .now)
                    let sessions = try await ABSClient[connectionID].listeningSessions(page: page, pageSize: pageSize)
                    
                    let filtered = sessions.filter { $0.startDate >= startOfDay }
                    let isFinished = sessions.isEmpty || filtered.count != sessions.count
                    
                    return (filtered, isFinished)
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
