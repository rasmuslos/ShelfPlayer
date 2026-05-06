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

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var offlineTimeout: Task<Void, Never>?

    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }

    func body(content: Content) -> some View {
        content
            .safeAreaInset(edge: .bottom) {
                VStack(spacing: 12) {
                    Group {
                        if offlineTimeout == nil {
                            Button("navigation.offline.enable", systemImage: "network.slash") {
                                OfflineMode.shared.forceEnable()
                            }
                        } else {
                            Button {
                                OfflineMode.shared.forceEnable()
                            } label: {
                                Text("\(Text("navigation.sync.failed.offline")) \(Text(.now.advanced(by: timeout + 1), style: .relative))")
                            }
                            .opacity(offlineTimeout == nil ? 0 : 1)
                        }
                    }
                    .buttonStyle(.glass)
                    .controlSize(.large)
                    .buttonSizing(.flexible)

                    if isCompact {
                        Menu {
                            LibraryPicker()

                            Divider()

                            Button("navigation.offline.enable", systemImage: "network.slash") {
                                OfflineMode.shared.forceEnable(reason: "Library picker offline button")
                            }
                            .onAppear {
                                offlineTimeout?.cancel()
                            }
                        } label: {
                            Text("navigation.library.select")
                        }
                        .buttonStyle(.glassProminent)
                        .controlSize(.large)
                        .buttonSizing(.flexible)
                    }
                }
                .padding(.horizontal, 20)
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
