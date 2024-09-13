//
//  LazyLoadHelper.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.09.24.
//

import Foundation
import SwiftUI
import ShelfPlayerKit

@Observable
internal class LazyLoadHelper<T: Item> {
    private static var PAGE_SIZE: Int {
        100
    }
    
    @MainActor private(set) internal var items: [T]
    @MainActor private(set) internal var count: Int
    
    @MainActor private(set) internal var failed: Bool
    @MainActor private(set) internal var working: Bool
    @MainActor private(set) internal var finished: Bool
    
    private let loadMore: (_ offset: Int) async throws -> ([T], Int)
    
    @MainActor
    init(loadMore: @escaping (_: Int) async throws -> ([T], Int)) {
        items = []
        count = 0
        
        failed = false
        working = true
        finished = false
        
        self.loadMore = loadMore
    }
    
    func initialLoad() {
        didReachEndOfLoadedContent()
    }
    func didReachEndOfLoadedContent() {
        Task {
            guard await !working, await !finished else {
                return
            }
            
            await MainActor.run {
                failed = false
                working = true
            }
            
            let itemCount = await items.count
            
            guard itemCount % Self.PAGE_SIZE == 0 else {
                await MainActor.run {
                    finished = true
                }
                
                return
            }
            
            let page: Int
            
            if itemCount == 0 {
                page = 0
            } else {
                page = itemCount / Self.PAGE_SIZE
            }
            
            do {
                let (received, totalCount) = try await loadMore(page)
                
                await MainActor.run {
                    items += received
                    count = totalCount
                    
                    working = false
                }
            } catch {
                await MainActor.run {
                    failed = true
                }
            }
        }
    }
}

internal extension LazyLoadHelper {
    @MainActor
    static func audiobooks(libraryID: String) -> LazyLoadHelper<Audiobook> {
        .init(loadMore: { try await AudiobookshelfClient.shared.audiobooks(libraryId: libraryID, limit: PAGE_SIZE, page: $0) })
    }
}
