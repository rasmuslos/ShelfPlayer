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
        @Environment(ViewModel.self) private var viewModel
        
        @ViewBuilder
        func emptyText(_ text: LocalizedStringKey) -> some View {
            if viewModel.sheetTab == .chapters {
                TipView(QueueScrollTip()) {
                    if $0.id == "queue" {
                        viewModel.sheetTab = .queue
                    }
                }
                .padding(.top, 8)
            }
            
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
            .padding(.top, 80)
        }
        
        @ViewBuilder
        func section(_ tab: ViewModel.SheetTab) -> some View {
            switch tab {
                case .queue:
                    ScrollViewReader { innerProxy in
                        List {
                            if viewModel.queue.isEmpty {
                                emptyText("queue.empty")
                            } else {
                                ForEach(viewModel.queue) { item in
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
                        .onChange(of: viewModel.sheetTab, initial: true) {
                            if let item = viewModel.queue.first {
                                innerProxy.scrollTo(item, anchor: .top)
                            }
                        }
                    }
                case .chapters:
                    ScrollViewReader { innerProxy in
                        List {
                            if !viewModel.chapters.isEmpty, let item = viewModel.item {
                                Chapters(item: item, chapters: viewModel.chapters)
                                    .padding(.horizontal, 20)
                            } else {
                                emptyText("chapters.empty")
                            }
                        }
                        .listStyle(.plain)
                        .contentMargins(.vertical, 4)
                        .onChange(of: viewModel.sheetTab, initial: true) {
                            if let id = viewModel.chapter?.id {
                                innerProxy.scrollTo("\(id)", anchor: .center)
                            }
                        }
                    }
                case .bookmarks:
                    List {
                        if viewModel.bookmarks.isEmpty {
                            emptyText("bookmarks.empty")
                        } else {
                            ForEach(viewModel.bookmarks) { bookmark in
                                Chapters.Row(id: "\(bookmark.position)", title: bookmark.note, time: bookmark.position, active: false, finished: false) {
                                    AudioPlayer.shared.itemCurrentTime = bookmark.position
                                }
                                .padding(.horizontal, 20)
                            }
                            .onDelete {
                                for index in $0 {
                                    viewModel.deleteBookmark(index: index)
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .contentMargins(.vertical, 4)
            }
        }
        
        var body: some View {
            if let item = viewModel.item {
                @Bindable var viewModel = viewModel
                
                VStack(spacing: 0) {
                    Header(item: item)
                    
                    GeometryReader { geometryProxy  in
                        ScrollViewReader { scrollProxy in
                            ScrollView {
                                LazyVStack(spacing: 0) {
                                    ForEach(ViewModel.SheetTab.allCases) { tab in
                                        section(tab)
                                            .id(tab)
                                            .frame(height: geometryProxy.size.height)
                                    }
                                }
                                .scrollTargetLayout()
                            }
                            .scrollIndicators(.hidden)
                            .scrollTargetBehavior(.paging)
                            .scrollPosition(id: $viewModel.sheetTab, anchor: .top)
                            .mask(
                                VStack(spacing: 0) {
                                    LinearGradient(gradient: Gradient(colors: [Color.black.opacity(0), Color.black]), startPoint: .top, endPoint: .bottom)
                                        .frame(height: 8)
                                    
                                    Rectangle()
                                        .fill(Color.black)
                                    
                                    LinearGradient(gradient: Gradient(colors: [Color.black, Color.black.opacity(0)]), startPoint: .top, endPoint: .bottom)
                                        .frame(height: 8)
                                }
                            )
                            .onChange(of: viewModel.sheetPresented, initial: true) {
                                scrollProxy.scrollTo(viewModel.sheetTab, anchor: .top)
                            }
                        }
                    }
                }
                .ignoresSafeArea(edges: .bottom)
                .presentationDetents([.fraction(0.7)])
                .sensoryFeedback(.selection, trigger: viewModel.sheetTab)
            }
        }
    }
}

private struct Header: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    let item: PlayableItem
    
    @ViewBuilder var button: some View {
        Button {
            AudioPlayer.shared.clear()
        } label: {
            Text("queue.clear")
                .font(.caption.smallCaps())
        }
        .buttonStyle(.bordered)
    }
    
    var body: some View {
        ZStack {
            button
                .hidden()
                .disabled(true)
            
            HStack(spacing: 8) {
                Text(viewModel.sheetTab?.label ?? "loading")
                    .font(.headline)
                
                Spacer(minLength: 4)
                
                if viewModel.sheetTab == .queue {
                    button
                        .transition(.opacity)
                }
                
                Menu {
                    Button {
                        viewModel.sheetTab = .queue
                    } label: {
                        Label("nowPlaying.sheet.queue", systemImage: "number")
                    }
                    Button {
                        viewModel.sheetTab = .chapters
                    } label: {
                        Label("nowPlaying.sheet.chapters", systemImage: "book.pages")
                    }
                    Button {
                        viewModel.sheetTab = .bookmarks
                    } label: {
                        Label("nowPlaying.sheet.bookmarks", systemImage: "star.fill")
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
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(.bar)
    }
}

private struct QueueScrollTip: Tip {
    var title: Text {
        .init("queue.scroll.tip.title")
    }
    var message: Text? {
        .init("queue.scroll.tip.message")
    }
    
    var actions: [Action] {[
        .init(id: "queue", title: "queue.view")
    ]}
}

private extension NowPlaying.ViewModel.SheetTab {
    var next: Self {
        switch self {
            case .queue:
                    .chapters
            case .chapters:
                    .bookmarks
            case .bookmarks:
                    .queue
        }
    }
    
    var label: LocalizedStringKey {
        switch self {
            case .queue:
                "Queue"
            case .chapters:
                "Chapters"
            case .bookmarks:
                "Bookmarks"
        }
    }
}
