//
//  AudiobookTagsPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI
import ShelfPlayback

struct AudiobookTagsPanel: View {
    @Environment(\.library) private var library

    @State private var tags: [String]?
    @State private var notifyError = false

    @State private var ascending = AppSettings.shared.tagsAscending

    private var sortedTags: [String]? {
        tags?.sorted { lhs, rhs in
            let result = lhs.localizedStandardCompare(rhs) == .orderedAscending
            return ascending ? result : !result
        }
    }

    var body: some View {
        Group {
            if let sortedTags {
                if sortedTags.isEmpty {
                    EmptyCollectionView()
                } else {
                    List(sortedTags, id: \.self) { tag in
                        NavigationLink(value: NavigationDestination.tagAudiobooks(tag)) {
                            Text(tag)
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                LoadingView()
            }
        }
        .navigationTitle("panel.tags")
        .largeTitleDisplayMode()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    withAnimation {
                        ascending.toggle()
                    }
                } label: {
                    Label("item.sort", systemImage: ascending ? "chevron.down" : "chevron.up")
                }
            }
        }
        .onChange(of: ascending) {
            AppSettings.shared.tagsAscending = ascending
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .hapticFeedback(.error, trigger: notifyError)
        .task {
            await loadTags()
        }
        .refreshable {
            await loadTags()
        }
    }

    private func loadTags() async {
        guard let library else {
            return
        }

        do {
            let tags = try await ABSClient[library.id.connectionID].tags(from: library.id.libraryID)

            withAnimation {
                self.tags = tags
            }
        } catch {
            withAnimation {
                notifyError.toggle()
                tags = []
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookTagsPanel()
            .previewEnvironment()
    }
}
#endif
