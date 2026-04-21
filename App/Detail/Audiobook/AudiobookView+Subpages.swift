//
//  AudiobookView+Subpages.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 21.04.26.
//

import SwiftUI
import ShelfPlayback

extension AudiobookView {
    struct BookmarksPage: View {
        @Environment(AudiobookViewModel.self) private var viewModel

        var body: some View {
            List {
                BookmarksList(itemID: viewModel.audiobook.id, bookmarks: viewModel.bookmarks)
            }
            .listStyle(.plain)
            .navigationTitle("item.bookmarks \(viewModel.bookmarks.count)")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(PlaybackSafeAreaPaddingModifier())
        }
    }

    struct ChaptersPage: View {
        @Environment(AudiobookViewModel.self) private var viewModel

        var body: some View {
            List {
                ChaptersList(itemID: viewModel.audiobook.id, chapters: viewModel.chapters)
            }
            .listStyle(.plain)
            .navigationTitle("item.chapters \(viewModel.chapters.count)")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(PlaybackSafeAreaPaddingModifier())
        }
    }

    struct TimelinePage: View {
        @Environment(AudiobookViewModel.self) private var viewModel

        var body: some View {
            ScrollView {
                Timeline(sessionLoader: viewModel.sessionLoader, item: viewModel.audiobook)
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
            }
            .navigationTitle("timeline")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(PlaybackSafeAreaPaddingModifier())
        }
    }

    struct DocumentsPage: View {
        @Environment(AudiobookViewModel.self) private var viewModel

        var body: some View {
            List {
                ForEach(viewModel.supplementaryPDFs, id: \.ino) { pdf in
                    Button(pdf.name) {
                        viewModel.presentPDF(pdf)
                    }
                }
            }
            .listStyle(.plain)
            .disabled(viewModel.loadingPDF)
            .navigationTitle("item.documents")
            .navigationBarTitleDisplayMode(.inline)
            .modifier(PlaybackSafeAreaPaddingModifier())
        }
    }
}
