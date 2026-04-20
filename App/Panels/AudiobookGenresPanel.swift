//
//  AudiobookGenresPanel.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 19.04.26.
//

import SwiftUI
import ShelfPlayback

struct AudiobookGenresPanel: View {
    @Environment(\.library) private var library

    @State private var genres: [String]?
    @State private var notifyError = false

    @State private var ascending = AppSettings.shared.genresAscending

    private var sortedGenres: [String]? {
        genres?.sorted { lhs, rhs in
            let result = lhs.localizedStandardCompare(rhs) == .orderedAscending
            return ascending ? result : !result
        }
    }

    var body: some View {
        Group {
            if let sortedGenres {
                if sortedGenres.isEmpty {
                    EmptyCollectionView()
                } else {
                    List(sortedGenres, id: \.self) { genre in
                        NavigationLink(value: NavigationDestination.genreAudiobooks(genre)) {
                            Text(genre)
                        }
                    }
                    .listStyle(.plain)
                }
            } else {
                LoadingView()
            }
        }
        .navigationTitle("panel.genres")
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
            AppSettings.shared.genresAscending = ascending
        }
        .modifier(PlaybackSafeAreaPaddingModifier())
        .hapticFeedback(.error, trigger: notifyError)
        .task {
            await loadGenres()
        }
        .refreshable {
            await loadGenres()
        }
    }

    private func loadGenres() async {
        guard let library else {
            return
        }

        do {
            let genres = try await ABSClient[library.id.connectionID].genres(from: library.id.libraryID)

            withAnimation {
                self.genres = genres
            }
        } catch {
            withAnimation {
                notifyError.toggle()
                genres = []
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookGenresPanel()
            .previewEnvironment()
    }
}
#endif
