//
//  LazyLoadHelper.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 13.09.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

@Observable
internal class LazyLoadHelper<T: Item, O: Any> {
    private static var PAGE_SIZE: Int {
        100
    }
    
    @MainActor private(set) internal var items: [T]
    @MainActor private(set) internal var count: Int
    
    @MainActor internal var sortOrder: O
    
    @MainActor private(set) internal var failed: Bool
    @MainActor private(set) internal var working: Bool
    @MainActor private(set) internal var finished: Bool
    
    @MainActor internal var libraryID: String!
    
    private let loadMore: (_ : Int, _ : O, _ : String) async throws -> ([T], Int)
    
    @MainActor
    init(sortOrder: O, loadMore: @escaping (_: Int, _ : O, _ : String) async throws -> ([T], Int)) {
        self.sortOrder = sortOrder
        
        items = []
        count = 0
        
        failed = false
        working = false
        finished = false
        
        self.loadMore = loadMore
    }
    
    func initialLoad() {
        didReachEndOfLoadedContent()
    }
    func refresh() async {
        await MainActor.run {
            items = []
            count = 0
            
            failed = false
            working = true
            finished = false
        }
        
        didReachEndOfLoadedContent(bypassWorking: true)
    }
    
    func didReachEndOfLoadedContent(bypassWorking: Bool = false) {
        Task {
            guard await !working || bypassWorking, await !finished else {
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
            
            let page = itemCount / Self.PAGE_SIZE
            
            do {
                let (received, totalCount) = try await loadMore(page, sortOrder, libraryID)
                
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
    static var audiobooks: LazyLoadHelper<Audiobook, AudiobookSortFilter.SortOrder> {
        .init(sortOrder: Defaults[.audiobooksSortOrder], loadMore: {
            try await AudiobookshelfClient.shared.audiobooks(libraryId: $2, sortOrder: $1.apiValue, limit: PAGE_SIZE, page: $0)
        })
    }
}
