//
//  AudiobookView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import ShelfPlayback

struct AudiobookView: View {
    @Environment(\.library) private var library

    @State private var viewModel: AudiobookViewModel

    init(_ audiobook: Audiobook) {
        _viewModel = .init(initialValue: .init(audiobook))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Header()
                    .padding(.horizontal, 20)

                Description(description: viewModel.audiobook.description)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)

                VStack(spacing: 0) {
                    if viewModel.bookmarks.count > 0 {
                        SubpageLink("item.bookmarks \(viewModel.bookmarks.count)") {
                            BookmarksPage()
                                .environment(viewModel)
                        }
                    }

                    if viewModel.chapters.count > 1 {
                        SubpageLink("item.chapters \(viewModel.chapters.count)") {
                            ChaptersPage()
                                .environment(viewModel)
                        }
                    }

                    SubpageLink("timeline") {
                        TimelinePage()
                            .environment(viewModel)
                    }

                    if !viewModel.supplementaryPDFs.isEmpty {
                        SubpageLink("item.documents") {
                            DocumentsPage()
                                .environment(viewModel)
                        }
                    }
                }
                .padding(.top, 32)
                .padding(.bottom, 16)

                VStack(spacing: 12) {
                    ForEach(viewModel.sameSeries, id: \.0.hashValue) { (series, audiobooks) in
                        AudiobookRow(title: String(localized: "item.related.audiobook.series \(series.name)"), small: true, audiobooks: audiobooks)
                    }
                    ForEach(viewModel.sameAuthor, id: \.0.hashValue) { (author, audiobooks) in
                        AudiobookRow(title: String(localized: "item.related.audiobook.author \(author)"), small: true, audiobooks: audiobooks)
                    }
                    ForEach(viewModel.sameNarrator, id: \.0.hashValue) { (narrator, audiobooks) in
                        AudiobookRow(title: String(localized: "item.related.audiobook.narrator \(narrator)"), small: true, audiobooks: audiobooks)
                    }
                }
                .padding(.vertical, 16)
                .background(.background.secondary)
                .padding(.top, 12)

                Spacer()
            }
        }
        .modifier(ToolbarModifier())
        .modifier(PlaybackSafeAreaPaddingModifier())
        .hapticFeedback(.error, trigger: viewModel.notifyError)
        .environment(viewModel)
        .onAppear {
            viewModel.library = library
        }
        .task {
            viewModel.load(refresh: false)
        }
        .refreshable {
            viewModel.load(refresh: true)
        }
        .userActivity("io.rfk.shelfPlayer.item") { activity in
            activity.title = viewModel.audiobook.name
            activity.isEligibleForHandoff = true
            activity.isEligibleForPrediction = true
            activity.persistentIdentifier = viewModel.audiobook.id.description

            Task {
                try await activity.webpageURL = viewModel.audiobook.id.url
            }
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookView(.fixture)
    }
    .previewEnvironment()
}
#endif
