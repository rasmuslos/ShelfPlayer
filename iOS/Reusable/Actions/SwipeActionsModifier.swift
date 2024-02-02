//
//  SwipeActionsModifier.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 13.10.23.
//

import SwiftUI
import SPBase
import SPOffline
import SPOfflineExtended

struct SwipeActionsModifier: ViewModifier {
    let item: PlayableItem
    let entity: OfflineProgress
    let offlineTracker: ItemOfflineTracker
    
    @MainActor
    init(item: PlayableItem) {
        self.item = item
        
        entity = OfflineManager.shared.requireProgressEntity(item: item)
        offlineTracker = item.offlineTracker
    }
    
    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                ProgressButton(item: item, tint: true)
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                DownloadButton(item: item, tint: true)
            }
    }
}
