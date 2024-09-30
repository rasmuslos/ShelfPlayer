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
        
        @State private var chaptersPosition: String? = nil
        
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
                    .contentMargins(.vertical, 8)
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
                    .scrollPosition(id: $chaptersPosition, anchor: .center)
                    .onAppear {
                        if let chapter = AudioPlayer.shared.chapter {
                            chaptersPosition = String(chapter.id)
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
                    if horizontalSizeClass == .compact {
                        CompactHeader(item: item, chapterPosition: $chaptersPosition)
                    }
                    
                    TabView(selection: $viewModel.sheetTab) {
                        ForEach(ViewModel.SheetTab.allCases) { tab in
                            section(tab)
                                .tag(tab)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
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
                    .safeAreaInset(edge: .bottom) {
                        ZStack {
                            ForEach(ViewModel.SheetTab.allCases) { tab in
                                Image(systemName: tab.icon)
                                    .hidden()
                            }
                            
                            HStack(spacing: 4) {
                                ForEach(ViewModel.SheetTab.allCases) { tab in
                                    Button {
                                        viewModel.sheetTab = tab
                                    } label: {
                                        Image(systemName: viewModel.sheetTab == tab ? tab.icon : "circle.fill")
                                            .fixedSize()
                                            .contentTransition(.symbolEffect(.replace))
                                            .scaleEffect(viewModel.sheetTab == tab ? 1 : 0.5)
                                            .animation(.smooth, value: viewModel.sheetTab)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }
                }
                .presentationDetents([.fraction(0.7)])
                .sensoryFeedback(.selection, trigger: viewModel.sheetTab)
            }
        }
    }
}

private struct CompactHeader: View {
    @Environment(NowPlaying.ViewModel.self) private var viewModel
    @Environment(\.dismiss) private var dismiss
    
    let item: PlayableItem
    @Binding var chapterPosition: String?
    
    @ViewBuilder var button: some View {
        Button {
            if viewModel.sheetTab == .queue {
                AudioPlayer.shared.clear()
            } else if viewModel.sheetTab == .chapters, let chapter = AudioPlayer.shared.chapter {
                chapterPosition = String(chapter.id)
            }
        } label: {
            Group {
                if viewModel.sheetTab == .queue {
                    Text("queue.clear")
                } else {
                    Text("chapters.now")
                }
            }
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
                Button {
                    viewModel.sheetTab = viewModel.sheetTab?.next
                } label: {
                    Text(viewModel.sheetTab?.label ?? "loading")
                        .font(.headline)
                }
                .buttonStyle(.plain)
                
                Spacer(minLength: 4)
                
                Group {
                    if viewModel.sheetTab == .queue {
                        button
                    } else if viewModel.sheetTab == .chapters, let chapter = viewModel.chapter, chapterPosition != String(chapter.id) {
                        button
                    }
                }
                .transition(.opacity)
                .animation(.smooth, value: viewModel.sheetTab)
                
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
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 20)
        .background(.bar)
    }
}
