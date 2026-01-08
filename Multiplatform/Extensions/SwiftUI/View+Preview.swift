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
            .environment(OfflineMode.shared)
            .environment(ConnectionStore.shared)
            .environment(Satellite.shared.debugPlayback())
        
            .environment(PlaybackViewModel.shared)
            .environment(ListenedTodayTracker.shared)
        
            .environment(ItemNavigationController())
            .environment(TabRouterViewModel().previewEnvironment())
        
            .environment(\.namespace, namespace)
    }
    #endif
}
