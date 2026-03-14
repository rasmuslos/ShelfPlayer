//
//  OfflineControlsModifier.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 18.09.25.
//

import SwiftUI
import ShelfPlayback

struct OfflineControlsModifier: ViewModifier {
    let timeout: TimeInterval = 21
    
    let startOfflineTimeout: Bool
    
    @State private var offlineTimeout: Task<Void, Never>?
    
    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    if !startOfflineTimeout {    
                        Button("navigation.offline.enable", systemImage: "network.slash") {
                            OfflineMode.shared.forceEnable()
                        }
                    } else {
                        Button {
                            OfflineMode.shared.forceEnable()
                        } label: {
                            Text("navigation.sync.failed.offline")
                            + Text(verbatim: " ")
                            + Text(.now.advanced(by: timeout + 1), style: .relative)
                        }
                        .opacity(offlineTimeout == nil ? 0 : 1)
                    }
                    
                    Menu {
                        LibraryPicker()
                        
                        Divider()
                        
                        Button("navigation.offline.enable", systemImage: "network.slash") {
                            OfflineMode.shared.forceEnable()
                        }
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
                            try await Task.sleep(for: .seconds(timeout))
                            try Task.checkCancellation()
                            
                            OfflineMode.shared.forceEnable()
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
#Preview {
    ContentUnavailableView("navigation.sync.failed", systemImage: "circle.badge.xmark", description: Text("navigation.sync.failed"))
        .modifier(OfflineControlsModifier(startOfflineTimeout: false))
        .previewEnvironment()
}
#endif
