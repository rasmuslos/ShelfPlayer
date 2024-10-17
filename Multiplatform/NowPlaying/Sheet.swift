//
//  NowPlayingSheet+Chapters.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SwiftData
import TipKit
import Defaults
import ShelfPlayerKit
import SPPlayback

internal extension NowPlaying {
    struct Sheet: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(ViewModel.self) private var viewModel
        
        private var isCompact: Bool {
            horizontalSizeClass == .compact
        }
        
        @ViewBuilder
        func emptyText(_ text: LocalizedStringKey) -> some View {
            VStack(spacing: 2) {
                Text(text)
                    .font(.callout)
                
                if !viewModel.queue.isEmpty {
                    Text("empty.other.queue \(viewModel.queue.count)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity)
            .listRowSeparator(.hidden)
            .listRowBackground(Color(UIColor.secondarySystemBackground))
            .padding(.top, 160)
        }
        
        var body: some View {
            if let item = viewModel.item {
                @Bindable var viewModel = viewModel
                
                GeometryReader { geometryProxy in
                    ScrollViewReader { scrollProxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 0) {
                                ForEach(viewModel.visibleSheetTabs) { tab in
                                    Group {
                                        switch tab {
                                        case .queue:
                                            queueContent
                                        case .chapters:
                                            chaptersContent
                                        case .bookmarks:
                                            bookmarksContent
                                        }
                                    }
                                    .id(tab)
                                    .frame(width: geometryProxy.size.width)
                                    .contentMargins(.top, isCompact ? 52 : 0)
                                    .contentMargins(.bottom, 52)
                                }
                            }
                            .scrollTargetLayout()
                        }
                        .scrollClipDisabled()
                        .scrollTargetBehavior(.paging)
                        .scrollPosition(id: $viewModel.sheetTab)
                        .onAppear {
                            scrollProxy.scrollTo(viewModel.sheetTab)
                        }
                    }
                }
                .background(.background.secondary)
                .overlay {
                    VStack(spacing: 0) {
                        if isCompact {
                            CompactHeader(item: item)
                        }
                        
                        Spacer()
                        
                        BottomToolbar()
                    }
                }
                .statusBarHidden()
                .ignoresSafeArea(edges: .bottom)
                .presentationDetents([.fraction(0.7)])
                .sensoryFeedback(.selection, trigger: viewModel.sheetTab)
            }
        }
    }
}

private extension NowPlaying.Sheet {
    @ViewBuilder
    var queueContent: some View {
        List {
            if viewModel.queue.isEmpty {
                emptyText("queue.empty")
            } else {
                ForEach(Array(viewModel.queue.enumerated()), id: \.offset) { index, item in
                    HStack(spacing: 0) {
                        ItemImage(cover: item.cover)
                            .frame(width: 48)
                            .padding(.trailing, 8)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .lineLimit(1)
                            
                            if let author = item.author {
                                Text(author)
                                    .lineLimit(1)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        
                        Spacer(minLength: 12)
                        
                        Label("drag", systemImage: "line.3.horizontal")
                            .labelStyle(.iconOnly)
                            .font(.title3)
                            .foregroundStyle(.secondary)
                    }
                    .id(item)
                    .listRowInsets(.init(top: 4, leading: 20, bottom: 4, trailing: 20))
                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                    .contentShape(.rect)
                    .contextMenu {
                        QueueContextMenuItems(item: item, index: index)
                    } preview: {
                        if let episode = item as? Episode {
                            EpisodeContextMenuModifier.Preview(episode: episode)
                        } else if let audiobook = item as? Audiobook {
                            AudiobookContextMenuModifier.Preview(audiobook: audiobook)
                        }
                    }
                }
                .onMove {
                    for index in $0 {
                        AudioPlayer.shared.move(from: index, to: $1)
                    }
                }
                .onDelete {
                    for index in $0 {
                        AudioPlayer.shared.remove(at: index)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
    
    @ViewBuilder
    var chaptersContent: some View {
        ScrollViewReader { innerProxy in
            List {
                if !viewModel.chapters.isEmpty, let item = viewModel.item {
                    Chapters(item: item, chapters: viewModel.chapters)
                        .padding(.horizontal, 20)
                        .listRowBackground(Color(UIColor.secondarySystemBackground))
                } else {
                    emptyText("chapters.empty")
                }
            }
            .listStyle(.plain)
            .onChange(of: viewModel.sheetPresented, initial: true) {
                innerProxy.scrollTo("\(viewModel.chapter?.id ?? -1)", anchor: .center)
            }
        }
    }
    
    @ViewBuilder
    var bookmarksContent: some View {
        List {
            if viewModel.bookmarks.isEmpty {
                emptyText("bookmarks.empty")
            } else {
                ForEach(Array(viewModel.bookmarks.enumerated()), id: \.offset) { index, bookmark in
                    Chapters.Row(id: "\(bookmark.position)", title: bookmark.note, time: bookmark.position, active: false, finished: false) {
                        AudioPlayer.shared.itemCurrentTime = bookmark.position
                    }
                    .padding(.horizontal, 20)
                    .listRowBackground(Color(UIColor.secondarySystemBackground))
                    .contextMenu {
                        Button {
                            viewModel.bookmarkEditingIndex = index
                        } label: {
                            Label("bookmark.edit", systemImage: "pencil.line")
                        }
                        
                        Button(role: .destructive) {
                            viewModel.deleteBookmark(index: index)
                        } label: {
                            Label("bookmark.remove", systemImage: "xmark")
                        }
                    }
                }
                .onDelete {
                    for index in $0 {
                        viewModel.deleteBookmark(index: index)
                    }
                }
            }
        }
        .listStyle(.plain)
    }
}

private struct CompactHeader: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    let item: PlayableItem
    
    var body: some View {
        HStack(spacing: 8) {
            Button {
                viewModel.sheetTab = viewModel.sheetTab?.next
            } label: {
                Text(viewModel.sheetTab?.label ?? "loading")
                    .font(.headline)
            }
            .buttonStyle(.plain)
            
            Spacer(minLength: 4)
            
            Menu {
                ForEach(NowPlaying.ViewModel.SheetTab.allCases) { tab in
                    Button {
                        withAnimation {
                            viewModel.sheetTab = tab
                        }
                    } label: {
                        Label(tab.label, systemImage: tab.icon)
                    }
                }
            } label: {
                Label("dismiss", systemImage: "xmark")
                    .labelStyle(.iconOnly)
                    .font(.title3)
                    .symbolVariant(.circle.fill)
                    .foregroundStyle(.secondary)
            } primaryAction: {
                dismiss()
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
        }
        .padding(.top, 12)
        .padding(.bottom, 16)
        .padding(.horizontal, 20)
        .background(.bar)
        .mask(
            VStack(spacing: 0) {
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 8)
                
                Rectangle()
                    .fill(Color.black)
            }
        )
    }
}

private struct BottomToolbar: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    
    private var clearVisible: Bool {
        viewModel.sheetTab == .queue && !viewModel.queue.isEmpty
    }
    
    @ViewBuilder
    private var remainingPercentage: some View {
        Text(viewModel.itemCurrentTime / viewModel.itemDuration, format: .percent.notation(.compactName))
            .font(.footnote)
            .foregroundStyle(.secondary)
            .contentTransition(.numericText())
    }
    @ViewBuilder
    private var clearButton: some View {
        Button {
            AudioPlayer.shared.clear()
        } label: {
            Text("queue.clear")
        }
        .buttonStyle(.plain)
        .font(.footnote)
        .foregroundStyle(.secondary)
    }
    
    var body: some View {
        ZStack {
            ForEach(NowPlaying.ViewModel.SheetTab.allCases) { tab in
                Image(systemName: tab.icon)
                    .hidden()
            }
            
            HStack(spacing: 4) {
                ZStack {
                    clearButton
                        .hidden()
                        .allowsHitTesting(false)
                    
                    remainingPercentage
                }
                
                Spacer()
                
                ForEach(viewModel.visibleSheetTabs) { tab in
                    let active = viewModel.sheetTab == tab
                    
                    Button {
                        viewModel.sheetTab = tab
                    } label: {
                        Image(systemName: active ? tab.icon : "circle.fill")
                            .fixedSize()
                            .scaleEffect(active ? 1 : 0.5)
                            .foregroundStyle(active ? .primary : .secondary)
                            .animation(.smooth, value: active)
                    }
                    .buttonStyle(.plain)
                }
                
                Spacer()
                
                clearButton
                    .opacity(clearVisible ? 1 : 0)
                    .allowsHitTesting(clearVisible)
                    .animation(.smooth, value: clearVisible)
            }
        }
        .padding(.top, 16)
        .padding(.bottom, 16)
        .padding(.horizontal, 32)
        .background(.bar)
        .mask(
            VStack(spacing: 0) {
                LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                    .frame(height: 8)
                
                Rectangle()
                    .fill(Color.black)
            }
        )
    }
}

private struct QueueContextMenuItems: View {
    @Environment(\.library) private var library
    
    let item: PlayableItem
    let index: Int
    
    private var isOffline: Bool {
        library.type == .offline
    }
    
    var body: some View {
        Group {
            if let episode = item as? Episode {
                Button {
                    Navigation.navigate(episodeID: episode.id, podcastID: episode.podcastId, libraryID: episode.libraryID)
                } label: {
                    Label("episode.view", systemImage: "play.square.stack")
                }
                
                Button {
                    Navigation.navigate(podcastID: episode.podcastId, libraryID: episode.libraryID)
                } label: {
                    Label("podcast.view", systemImage: "rectangle.stack")
                    Text(episode.podcastName)
                }
            }
            
            if let audiobook = item as? Audiobook {
                Button {
                    Navigation.navigate(audiobookID: audiobook.id, libraryID: audiobook.libraryID)
                } label: {
                    Label("audiobook.view", systemImage: "book")
                }
                
                if let author = audiobook.author {
                    Button {
                        Task {
                            if let authorID = try? await AudiobookshelfClient.shared.authorID(name: author, libraryID: audiobook.libraryID) {
                                Navigation.navigate(authorID: authorID, libraryID: audiobook.libraryID)
                            }
                        }
                    } label: {
                        Label("author.view", systemImage: "person")
                    }
                }
                
                if !audiobook.series.isEmpty {
                    if audiobook.series.count == 1, let series = audiobook.series.first {
                        Button {
                            Navigation.navigate(seriesName: series.name, seriesID: series.id, libraryID: audiobook.libraryID)
                        } label: {
                            Label("series.view", systemImage: "rectangle.grid.2x2.fill")
                            Text(series.name)
                        }
                    } else {
                        Menu {
                            ForEach(audiobook.series, id: \.name) { series in
                                Button {
                                    Navigation.navigate(seriesName: series.name, seriesID: series.id, libraryID: audiobook.libraryID)
                                } label: {
                                    Text(series.name)
                                }
                            }
                        } label: {
                            Label("series.view", systemImage: "rectangle.grid.2x2.fill")
                        }
                    }
                }
            }
        }
        .disabled(isOffline)
        
        Divider()
        
        if index != 0 {
            Button {
                AudioPlayer.shared.move(from: index, to: 0)
            } label: {
                Label("queue.top", systemImage: "text.line.first.and.arrowtriangle.forward")
            }
        }
        if index != AudioPlayer.shared.queue.count - 1 {
            Button {
                AudioPlayer.shared.move(from: index, to: AudioPlayer.shared.queue.count - 1)
            } label: {
                Label("queue.bottom", systemImage: "text.line.last.and.arrowtriangle.forward")
            }
        }
        
        Divider()
        
        ProgressButton(item: item) {
            AudioPlayer.shared.remove(at: index)
        }
        DownloadButton(item: item)
        
        Divider()
        
        Button(role: .destructive) {
            AudioPlayer.shared.remove(at: index)
        } label: {
            Label("queue.remove", systemImage: "xmark")
        }
    }
}
