//
//  ProgressResetButton.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 29.01.25.
//

import SwiftUI
import ShelfPlayerKit

struct ProgressResetButton: View {
    @Environment(Satellite.self) private var satellite
    
    let item: PlayableItem
    
    @State private var progress: ProgressTracker
    
    init(item: PlayableItem) {
        self.item = item
        _progress = .init(initialValue: .init(itemID: item.id))
    }
    
    var body: some View {
        if let entity = progress.entity, entity.progress > 0 {
            Button("progress.reset", systemImage: "square.slash", role: .destructive) {
                satellite.deleteProgress(item)
            }
            .disabled(satellite.isLoading(observing: item.id))
        }
    }
}
