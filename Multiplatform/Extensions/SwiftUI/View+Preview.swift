//
//  View+Modify.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 17.10.24.
//

import Foundation
import SwiftUI
import ShelfPlayback

extension View {
    #if DEBUG
    @ViewBuilder
    func previewEnvironment() -> some View {
        @Namespace var namespace
        
        self
            .environment(Satellite.shared.debugPlayback())
            .environment(PlaybackViewModel.shared)
            .environment(ConnectionStore.shared)
            .environment(ProgressViewModel.shared)
            .environment(ListenedTodayTracker.shared)
            .environment(OfflineMode.shared)
            .environment(\.namespace, namespace)
    }
    #endif
}
