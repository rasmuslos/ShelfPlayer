//
//  SyncGate.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 26.05.25.
//

import SwiftUI
import ShelfPlayback

struct SyncGate<Content: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(ProgressViewModel.self) private var progressViewModel
    
    let library: Library
    let content: () -> Content
    
    @State private var offlineTimeout: Task<Void, Never>?
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        if progressViewModel.importedConnectionIDs.contains(library.connectionID) {
            content()
        } else {
            Group {
                if progressViewModel.importFailedConnectionIDs.contains(library.connectionID) {
                    ContentUnavailableView("navigation.sync.failed", systemImage: "circle.badge.xmark", description: Text("navigation.sync.failed"))
                        .symbolRenderingMode(.multicolor)
                        .symbolEffect(.wiggle, options: .nonRepeating)
                        .safeAreaInset(edge: .bottom) {
                            Button {
                                offlineTimeout?.cancel()
                            } label: {
                                Text("navigation.sync.failed.offline")
                                + Text(verbatim: " ")
                                + Text(.now.advanced(by: 6), style: .relative)
                            }
                            .opacity(offlineTimeout == nil ? 0 : 1)
                        }
                        .onAppear {
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
                        .onDisappear {
                            offlineTimeout?.cancel()
                        }
                } else {
                    ContentUnavailableView("navigation.sync", systemImage: "binoculars")
                        .symbolEffect(.pulse)
                        .onAppear {
                            progressViewModel.attemptSync(for: library.connectionID)
                        }
                }
            }
            .toolbarVisibility(isCompact ? .hidden : .automatic, for: .tabBar)
            .safeAreaInset(edge: .bottom) {
                if isCompact {
                    Menu("navigation.library.select") {
                        LibraryPicker(isSearchVisible: false)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .padding(.bottom, 8)
                }
            }
        }
    }
}

#if DEBUG
#Preview {
    SyncGate(library: Library(id: "fixture", connectionID: "fixture", name: "Fixture", type: "book", index: 0)) {
        Text(verbatim: ":)")
    }
    .previewEnvironment()
}
#endif
