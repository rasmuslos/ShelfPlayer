//
//  AudiobookView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import Defaults
import ShelfPlayback

struct AudiobookView: View {
    @Environment(\.defaultMinListRowHeight) private var minimumHeight
    @Environment(\.library) private var library
    
    @Default(.tintColor) private var tintColor
    
    @State private var viewModel: AudiobookViewModel
    
    init(_ audiobook: Audiobook) {
        _viewModel = .init(initialValue: .init(audiobook))
    }
    
    private let divider: some View = Divider()
        .padding(.horizontal, 20)
        .padding(.vertical, 24)
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                Header()
                    .padding(.horizontal, 20)
                
                divider
                
                Description(description: viewModel.audiobook.description)
                    .padding(.horizontal, 20)
                
                divider
                
                if viewModel.bookmarks.count > 0 {
                    DisclosureGroup("item.bookmarks \(viewModel.bookmarks.count)", isExpanded: $viewModel.bookmarksVisible) {
                        List {
                            BookmarksList(itemID: viewModel.audiobook.id, bookmarks: viewModel.bookmarks)
                        }
                        .listStyle(.plain)
                        .frame(height: minimumHeight * CGFloat(viewModel.bookmarks.count))
                    }
                    .disclosureGroupStyle(BetterDisclosureGroupStyle())
                    .padding(.bottom, 16)
                }
                
                if viewModel.chapters.count > 1 {
                    DisclosureGroup("item.chapters \(viewModel.chapters.count)", isExpanded: $viewModel.chaptersVisible) {
                        List {
                            ChaptersList(itemID: viewModel.audiobook.id, chapters: viewModel.chapters)
                        }
                        .listStyle(.plain)
                        .frame(height: minimumHeight * CGFloat(viewModel.chapters.count))
                    }
                    .disclosureGroupStyle(BetterDisclosureGroupStyle())
                    .padding(.bottom, 16)
                }
                
                DisclosureGroup("timeline", isExpanded: $viewModel.sessionsVisible) {
                    Timeline(sessionLoader: viewModel.sessionLoader, item: viewModel.audiobook)
                        .padding(.top, 8)
                        .padding(.horizontal, 20)
                }
                .disclosureGroupStyle(BetterDisclosureGroupStyle())
                .padding(.bottom, 16)
                
                if !viewModel.supplementaryPDFs.isEmpty {
                    DisclosureGroup("item.documents", isExpanded: $viewModel.supplementaryPDFsVisible) {
                        List {
                            ForEach(viewModel.supplementaryPDFs, id: \.ino) { pdf in
                                Button(pdf.name) {
                                    viewModel.presentPDF(pdf)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .disabled(viewModel.loadingPDF)
                        .frame(height: minimumHeight * CGFloat(viewModel.supplementaryPDFs.count))
                    }
                    .disclosureGroupStyle(BetterDisclosureGroupStyle())
                }
                
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
        .sensoryFeedback(.error, trigger: viewModel.notifyError)
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
