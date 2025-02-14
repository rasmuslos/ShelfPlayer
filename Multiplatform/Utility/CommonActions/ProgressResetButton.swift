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
    
    @State private var progressEntity: ProgressEntity.UpdatingProgressEntity?
    
    var body: some View {
        if progressEntity == nil {
            Color.clear
                .task {
                    progressEntity = await PersistenceManager.shared.progress[item.id].updating
                }
        } else if let progressEntity, progressEntity.progress > 0 {
            Button("progress.reset", systemImage: "slash.circle", role: .destructive) {
                satellite.deleteProgress(item)
            }
            .disabled(satellite.isLoading)
        }
    }
}
