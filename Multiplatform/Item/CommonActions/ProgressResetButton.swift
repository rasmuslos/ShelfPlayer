//
//  ProgressResetButton.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayback

struct ProgressResetButton: View {
    @Environment(Satellite.self) private var satellite
    
    let itemID: ItemIdentifier
    
    @State private var tracker: ProgressTracker
    
    init(itemID: ItemIdentifier) {
        self.itemID = itemID
        _tracker = .init(initialValue: .init(itemID: itemID))
    }
    
    var body: some View {
        if let progress = tracker.progress, progress > 0 {
            Button("item.progress.reset", systemImage: "square.slash", role: .destructive) {
                satellite.deleteProgress(itemID)
            }
            .disabled(satellite.isLoading(observing: itemID))
        }
    }
}
