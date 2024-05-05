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
