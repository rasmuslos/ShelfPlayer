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
                FullscreenBackground(threshold: horizontalSizeClass == .regular ? -90 : -310, backgroundColor: .clear, isToolbarVisible: $viewModel.toolbarVisible)
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
    
    @ViewBuilder
    private var authorLabel: some View {
        if !viewModel.audiobook.authors.isEmpty {
            Text(viewModel.audiobook.authors, format: .list(type: .and, width: .short))
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
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(viewModel.audiobook.name)
                .font(largeFont ? .title : .headline)
                .modifier(SerifModifier())
                .lineLimit(4)
                .multilineTextAlignment(alignment.textAlignment)
            
            if viewModel.audiobook.authors.count > 1 {
                Menu {
                    AuthorMenu.AuthorsMenu(authors: viewModel.audiobook.authors, libraryID: nil)
                } label: {
                    authorLabel
                }
                .menuStyle(.button)
                .buttonStyle(.plain)
            } else if let authorName = viewModel.audiobook.authors.first {
                NavigationLink {
                    AuthorLoadView(authorName: authorName)
                } label: {
                    authorLabel
                }
                .buttonStyle(.plain)
            }
        
            HStack(spacing: 2) {
                if !viewModel.audiobook.narrators.isEmpty {
                    Group {
                        Text("audiobook.narrator")
                        + Text(viewModel.audiobook.narrators, format: .list(type: .and, width: .short))
                    }
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
                    if !viewModel.audiobook.narrators.isEmpty || viewModel.audiobook.explicit || viewModel.audiobook.abridged {
                        Text(verbatim: " • ")
                    }
                    
                    Text(viewModel.audiobook.duration, format: .duration(unitsStyle: .short, allowedUnits: [.hour, .minute, .second], maximumUnitCount: 2))
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
            ItemImage(item: viewModel.audiobook, aspectRatio: .none, contrastConfiguration: .init(shadowRadius: 30, shadowOpacity: 0.2))
                .padding(.horizontal, 40)
            
            SeriesName()
            
            Title(largeFont: false, alignment: .center)
                .padding(.top, 12)
                .padding(.bottom, 16)
            
            PlayButton(item: viewModel.audiobook, color: viewModel.dominantColor)
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
                ItemImage(item: viewModel.audiobook, aspectRatio: .none, contrastConfiguration: .init(shadowRadius: 40, shadowOpacity: 0.6))
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
                            
                            PlayButton(item: viewModel.audiobook, color: viewModel.dominantColor)
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
