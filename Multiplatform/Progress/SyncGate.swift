//
//  SyncGate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.05.25.
//

import SwiftUI
import ShelfPlayback

struct SyncGate: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(ProgressViewModel.self) private var progressViewModel
    
    @Environment(ConnectionStore.self) private var connectionStore
    @Environment(Satellite.self) private var satellite
    
    let library: Library
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        Group {
            if progressViewModel.importFailedConnectionIDs.contains(library.connectionID) {
                ContentUnavailableView("navigation.sync.failed", systemImage: "circle.badge.xmark", description: Text("navigation.sync.failed"))
                    .symbolRenderingMode(.multicolor)
                    .symbolEffect(.wiggle, options: .nonRepeating)
                    .modifier(OfflineControlsModifier(startOfflineTimeout: true))
                    .onAppear {
                        guard connectionStore.libraries[library.connectionID]?.contains(where: { $0 == library }) != true, satellite.tabValue?.library == library else {
                            return
                        }
                        
                        RFNotification[.invalidateTab].send()
                    }
            } else {
                ContentUnavailableView("navigation.sync", systemImage: "binoculars")
                    .symbolEffect(.pulse)
                    .modifier(OfflineControlsModifier(startOfflineTimeout: false))
                    .onAppear {
                        progressViewModel.attemptSync(for: library.connectionID)
                    }
            }
        }
    }
}

#if DEBUG
#Preview {
    SyncGate(library: .fixture)
        .previewEnvironment()
}
#endif
