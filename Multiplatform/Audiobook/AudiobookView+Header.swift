//
//  AudiobookView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SPFoundation

internal extension AudiobookView {
    struct Header: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(AudiobookViewModel.self) private var viewModel
        
        var body: some View {
            @Bindable var viewModel = viewModel
            
            ZStack(alignment: .top) {
                FullscreenBackground(threshold: horizontalSizeClass == .regular ? -90 : -240, backgroundColor: .clear, navigationBarVisible: $viewModel.toolbarVisible)
                    .frame(height: 0)
                
                ViewThatFits {
                    RegularPresentation()
                    CompactPresentation()
                }
            }
        }
    }
}

private struct Title: View {
    @Environment(AudiobookViewModel.self) private var viewModel
    
    let largeFont: Bool
    let alignment: HorizontalAlignment
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(viewModel.audiobook.name)
                .font(largeFont ? .title : .headline)
                .modifier(SerifModifier())
                .lineLimit(4)
                .multilineTextAlignment(alignment.textAlignment)
            
            if let author = viewModel.audiobook.author {
                NavigationLink {
                    if let authorId = viewModel.authorID {
                        AuthorLoadView(authorId: authorId)
                    } else {
                        AuthorUnavailableView()
                    }
                } label: {
                    Text(author)
                        .font(largeFont ? .title2 : .subheadline)
                        .lineLimit(1)
                        .overlay(alignment: .trailingLastTextBaseline) {
                            Label("author.view", systemImage: "chevron.right.circle")
                                .labelStyle(.iconOnly)
                                .imageScale(.small)
                                .offset(x: 17)
                        }
                        .font(.subheadline)
                }
                .buttonStyle(.plain)
            }
            
            HStack(spacing: 2) {
                if let narrator = viewModel.audiobook.narrator {
                    Text("audiobook.narrator \(narrator)")
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }
                
                if viewModel.audiobook.explicit {
                    Label("explicit", systemImage: "e.square.fill")
                        .labelStyle(.iconOnly)
                }
                if viewModel.audiobook.abridged {
                    Label("abridged", systemImage: "a.square.fill")
                        .labelStyle(.iconOnly)
                }
                
                Group {
                    if viewModel.audiobook.narrator != nil || viewModel.audiobook.explicit || viewModel.audiobook.abridged {
                        Text(verbatim: " • ")
                    }
                    
                    Text(viewModel.audiobook.duration, format: .duration)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .foregroundStyle(.secondary)
            .imageScale(.small)
        }
    }
}

private struct SeriesName: View {
    @Environment(AudiobookViewModel.self) private var viewModel
    
    var body: some View {
        if !viewModel.audiobook.series.isEmpty, let seriesName = viewModel.audiobook.seriesName {
            Group {
                if viewModel.audiobook.series.count == 1, let series = viewModel.audiobook.series.first {
                    NavigationLink(destination: SeriesLoadView(series: series)) {
                        seriesNameComponent(seriesName)
                    }
                    .buttonStyle(.plain)
                } else {
                    Menu {
                        ForEach(viewModel.audiobook.series, id: \.name) { series in
                            NavigationLink(destination: SeriesLoadView(series: series)) {
                                seriesNameComponent(series.name)
                            }
                        }
                    } label: {
                        seriesNameComponent(seriesName)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.top, 8)
        }
    }
}

private struct CompactPresentation: View {
    @Environment(AudiobookViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ItemImage(cover: viewModel.audiobook.cover, aspectRatio: .none)
                .padding(.horizontal, 40)
                .shadow(radius: 40)
            
            SeriesName()
            
            Title(largeFont: false, alignment: .center)
                .padding(.top, 12)
                .padding(.bottom, 16)
            
            PlayButton(item: viewModel.audiobook, queue: [], color: viewModel.dominantColor)
        }
        .padding(.top, 32)
    }
}

private struct RegularPresentation: View {
    @Environment(AudiobookViewModel.self) private var viewModel
    
    @State private var availableWidth: CGFloat = .infinity
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                Color.clear
                    .onChange(of: proxy.size.width, initial: true) {
                        availableWidth = proxy.size.width
                    }
            }
            .frame(height: 0)
            
            HStack(spacing: 40) {
                ItemImage(cover: viewModel.audiobook.cover, aspectRatio: .none)
                    .shadow(radius: 40)
                    .frame(width: max(0, min(400, (availableWidth - 40) / 2)))
                    .hoverEffect(.highlight)
                
                Color.clear
                    .frame(minWidth: 280)
                    .overlay {
                        VStack(alignment: .leading, spacing: 4) {
                            Spacer()
                            
                            SeriesName()
                            Title(largeFont: true, alignment: .leading)
                                .padding(.trailing, 16)
                            
                            Spacer()
                            
                            PlayButton(item: viewModel.audiobook, queue: [], color: viewModel.dominantColor)
                        }
                    }
            }
        }
        .padding(.top, 12)
    }
}

private func seriesNameComponent(_ name: String) -> some View {
    Text(name)
        .font(.caption)
        .bold()
        .underline()
        .lineLimit(1)
}
