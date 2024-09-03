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
        
        var body: some View {
            if let item = viewModel.item {
                ScrollViewReader { proxy in
                    List {
                        Group {
                            if viewModel.sheetTab == .queue {
                                
                            } else if viewModel.sheetTab == .chapters {
                                Chapters(item: item, chapters: viewModel.chapters)
                                    .padding(.horizontal, 20)
                            } else if viewModel.sheetTab == .bookmarks {
                                
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
                        if viewModel.sheetTab == .chapters {
                            proxy.scrollTo(viewModel.chapter?.id, anchor: .center)
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
