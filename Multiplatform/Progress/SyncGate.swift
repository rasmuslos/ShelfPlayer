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
                        LibraryPicker()
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
    SyncGate(library: Library(id: "fixture", connectionID: "fixture", name: "Fixture", type: "audiobooks", index: 0)) {
        Text(verbatim: ":)")
    }
    .previewEnvironment()
}
#endif
