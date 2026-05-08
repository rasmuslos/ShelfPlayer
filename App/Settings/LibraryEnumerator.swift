//
//  LibraryEnumerator.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 25.10.25.
//

import SwiftUI
import OSLog
import ShelfPlayback

private let libraryEnumeratorLogger = Logger(subsystem: "io.rfk.shelfPlayer", category: "LibraryEnumerator")

struct LibraryEnumerator<SectionLabel: View, Label: View>: View {
    @Environment(ConnectionStore.self) private var connectionStore

    @ViewBuilder let sectionLabel: (_ name: String, _ content: () -> AnyView) -> SectionLabel
    @ViewBuilder let label: (_ : Library) -> Label

    var body: some View {
        ForEach(connectionStore.connections) { connection in
            sectionLabel(connection.name) {
                AnyView(erasing: SectionInner(connectionID: connection.id, label: label))
            }
        }
    }
}

private struct SectionInner<Label: View>: View {
    let connectionID: ItemIdentifier.ConnectionID
    @ViewBuilder let label: (_ : Library) -> Label

    @State private var isLoading = true
    @State private var libraries = [Library]()

    var body: some View {
        Group {
            if libraries.isEmpty {
                if isLoading {
                    ProgressView()
                        .task {
                            do {
                                self.libraries = try await ABSClient[connectionID].libraries()
                            } catch {
                                libraryEnumeratorLogger.warning("Failed to fetch libraries for \(connectionID, privacy: .public): \(error, privacy: .public)")
                            }

                            isLoading = false
                        }
                } else {
                    SwiftUI.Label("error.libraryLoadFailed", systemImage: "exclamationmark.triangle")
                        .foregroundStyle(.secondary)
                }
            } else {
                ForEach(libraries) {
                    label($0)
                }
            }
        }
        .animation(.smooth, value: libraries.map(\.id))
        .animation(.smooth, value: isLoading)
    }
}

#if DEBUG
#Preview("LibraryEnumerator") {
    List {
        LibraryEnumerator { name, content in
            Section(name) {
                content()
            }
        } label: {
            Text($0.name)
        }
    }
    .previewEnvironment()
}

#Preview("SectionInner") {
    List {
        SectionInner(connectionID: Library.fixture.id.connectionID) {
            Text($0.name)
        }
    }
    .previewEnvironment()
}
#endif
