//
//  NowPlayingSheet+Chapters.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 11.10.23.
//

import SwiftUI
import SwiftData
import Defaults
import ShelfPlayerKit
import SPPlayback

internal extension NowPlaying {
    struct Sheet: View {
        @Environment(ViewModel.self) private var viewModel
        
        @ViewBuilder
        func emptyText(_ text: LocalizedStringKey) -> some View {
            VStack {
                Text(text)
                    .font(.headline)
                
                if viewModel.queue.isEmpty {
                    Text("empty.other.queue \(viewModel.queue.count)")
                }
            }
            .padding(.top, 100)
            .listRowSeparator(.hidden)
        }
        
        var body: some View {
            if let item = viewModel.item {
                ScrollViewReader { proxy in
                    List {
                        Group {
                            if viewModel.sheetTab == .queue {
                                if viewModel.queue.isEmpty {
                                    emptyText("queue.empty")
                                } else {
                                    ForEach(viewModel.queue) {
                                        Text($0.name)
                                    }
                                }
                            } else if viewModel.sheetTab == .chapters {
                                if viewModel.chapters.isEmpty {
                                    emptyText("chapters.empty")
                                } else {
                                    Chapters(item: item, chapters: viewModel.chapters)
                                        .padding(.horizontal, 20)
                                }
                            } else if viewModel.sheetTab == .bookmarks {
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
                        }
                        .transition(.move(edge: .bottom))
                    }
                    .listStyle(.plain)
                    .safeAreaInset(edge: .top) {
                        HStack(spacing: 0) {
                            ItemImage(cover: item.cover)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(item.name)
                                    .font(.headline)
                                    .lineLimit(2)
                                    .modifier(SerifModifier())
                                
                                if let author = item.author {
                                    Text(author)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                            }
                            .padding(.leading, 12)
                            
                            Spacer()
                            
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
                                Label("nowPlaying.sheet.icon", systemImage: viewModel.sheetLabelIcon)
                                    .labelStyle(.iconOnly)
                                    .font(.title3)
                                    .foregroundStyle(.primary)
                            } primaryAction: {
                                viewModel.sheetTab = viewModel.sheetTab.next
                            }
                            .menuStyle(.button)
                            .buttonStyle(.plain)
                            .frame(height: 40)
                        }
                        .frame(height: 60)
                        .padding(20)
                        .background(.background.secondary)
                    }
                    .presentationDragIndicator(.visible)
                    .presentationDetents([.medium, .large])
                    .onChange(of: viewModel.sheetTab, initial: true) {
                        if viewModel.sheetTab == .chapters, let id = viewModel.chapter?.id {
                            proxy.scrollTo("\(id)", anchor: .center)
                        }
                    }
                }
            }
        }
    }
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
}
