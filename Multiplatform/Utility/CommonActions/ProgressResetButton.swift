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
    
    var body: some View {
        Button("progress.reset", systemImage: "slash.circle", role: .destructive) {
            satellite.deleteProgress(item)
        }
        .disabled(satellite.isLoading)
    }
}
