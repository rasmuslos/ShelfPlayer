//
//  AudiobookView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import ShelfPlayerKit

internal struct AudiobookView: View {
    @Environment(\.defaultMinListRowHeight) private var minimumHeight
    @State private var viewModel: AudiobookViewModel
    
    internal init(_ audiobook: Audiobook) {
        _viewModel = .init(initialValue: .init(audiobook: audiobook))
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
                
                if viewModel.chapters.count > 1 {
                    DisclosureGroup("\(viewModel.chapters.count) chapters", isExpanded: $viewModel.chaptersVisible) {
                        List {
                            Chapters(item: viewModel.audiobook, chapters: viewModel.chapters)
                        }
                        .listStyle(.plain)
                        .frame(height: minimumHeight * CGFloat(viewModel.chapters.count))
                    }
                    .disclosureGroupStyle(BetterDisclosureGroupStyle())
                    .padding(.bottom, 16)
                    .padding(.horizontal, 20)
                }
                
                DisclosureGroup("timeline", isExpanded: $viewModel.sessionsVisible) {
                    Timeline(item: viewModel.audiobook, sessions: viewModel.sessions)
                        .padding(.top, 8)
                }
                .disclosureGroupStyle(BetterDisclosureGroupStyle(horizontalLabelPadding: 20))
                
                divider
                
                if viewModel.sameSeries.count > 1 {
                    AudiobookRow(title: String(localized: "audiobook.similar.series"), audiobooks: viewModel.sameSeries)
                        .padding(.bottom, 20)
                }
                if viewModel.sameAuthor.count > 1, let author = viewModel.audiobook.author {
                    AudiobookRow(title: String(localized: "audiobook.similar.author \(author)"), audiobooks: viewModel.sameAuthor)
                        .padding(.bottom, 20)
                }
                if viewModel.sameNarrator.count > 1, let narrator = viewModel.audiobook.narrator {
                    AudiobookRow(title: String(localized: "audiobook.similar.narrator \(narrator)"), audiobooks: viewModel.sameNarrator)
                }
                
                Spacer()
            }
        }
        .modifier(NowPlaying.SafeAreaModifier())
        .modifier(ToolbarModifier())
        .sensoryFeedback(.error, trigger: viewModel.errorNotify)
        .environment(viewModel)
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .userActivity("io.rfk.shelfplayer.audiobook") {
            $0.title = viewModel.audiobook.name
            $0.isEligibleForHandoff = true
            $0.persistentIdentifier = viewModel.audiobook.id
            $0.targetContentIdentifier = "audiobook:\(viewModel.audiobook.id)"
            $0.userInfo = [
                "audiobookId": viewModel.audiobook.id,
            ]
            $0.webpageURL = AudiobookshelfClient.shared.serverUrl.appending(path: "item").appending(path: viewModel.audiobook.id)
        }
    }
}

#if DEBUG
#Preview {
    NavigationStack {
        AudiobookView(.fixture)
    }
}
#endif
