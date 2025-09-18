//
//  OfflineControlsModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 18.09.25.
//

import SwiftUI
import ShelfPlayback

struct OfflineControlsModifier: ViewModifier {
    let startOfflineTimeout: Bool
    
    @State private var offlineTimeout: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Button {
                        RFNotification[.changeOfflineMode].send(payload: true)
                    } label: {
                        Text("navigation.sync.failed.offline")
                        + Text(verbatim: " ")
                        + Text(.now.advanced(by: 6), style: .relative)
                    }
                    .opacity(offlineTimeout == nil ? 0 : 1)
                    
                    Menu {
                        LibraryPicker()
                            .onAppear {
                                offlineTimeout?.cancel()
                            }
                    } label: {
                        Text("navigation.library.select")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .onAppear {
                if startOfflineTimeout {
                    offlineTimeout = .init {
                        do {
                            try await Task.sleep(for: .seconds(5))
                            try Task.checkCancellation()
                            
                            await RFNotification[.changeOfflineMode].send(payload: true)
                        } catch {
                            offlineTimeout = nil
                        }
                    }
                }
            }
            .onDisappear {
                offlineTimeout?.cancel()
            }
    }
}

#if DEBUG
#Preview {
    ContentUnavailableView("navigation.sync.failed", systemImage: "circle.badge.xmark", description: Text("navigation.sync.failed"))
        .modifier(OfflineControlsModifier(startOfflineTimeout: true))
        .previewEnvironment()
}
#endif
