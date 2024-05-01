//
//  AudiobookView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI
import SPBase

extension AudiobookView {
    struct Header: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(AudiobookViewModel.self) private var viewModel
        
        private static func seriesNameComponent(_ name: String) -> some View {
            Text(name)
                .font(.caption)
                .bold()
                .underline()
                .lineLimit(1)
        }
        
        var body: some View {
            ZStack(alignment: .top) {
                FullscreenBackground(threshold: horizontalSizeClass == .regular ? -90 : -240, backgroundColor: .clear, navigationBarVisible: .init(get: { viewModel.navigationBarVisible }, set: { viewModel.navigationBarVisible = $0 }))
                    .frame(height: 0)
                
                // `ViewThatFits` does not work here.
                if horizontalSizeClass == .regular {
                    RegularPresentation()
                } else {
                    CompactPresentation()
                }
            }
        }
    }
}

extension AudiobookView.Header {
    struct Title: View {
        @Environment(AudiobookViewModel.self) private var viewModel
        
        let largeFont: Bool
        let alignment: HorizontalAlignment
        
        var body: some View {
            VStack(alignment: alignment, spacing: 5) {
                Text(viewModel.audiobook.name)
                    .font(largeFont ? .title : .headline)
                    .modifier(SerifModifier())
                    .lineLimit(4)
                    .multilineTextAlignment(alignment == .center ? .center : .leading)
                
                if let author = viewModel.audiobook.author {
                    NavigationLink {
                        if let authorId = viewModel.authorId {
                            AuthorLoadView(authorId: authorId)
                        } else {
                            AuthorUnavailableView()
                        }
                    } label: {
                        Text(author)
                            .font(largeFont ? .title2 : .subheadline)
                            .lineLimit(1)
                            .overlay(alignment: .trailingLastTextBaseline) {
                                Image(systemName: "chevron.right.circle")
                                    .imageScale(.small)
                                    .offset(x: 17)
                            }
                            .font(.subheadline)
                    }
                    .buttonStyle(.plain)
                }
                
                HStack(spacing: 3) {
                    if let narrator = viewModel.audiobook.narrator {
                        Text("audiobook.narrator \(narrator)")
                            .font(.caption)
                            .lineLimit(1)
                            .foregroundStyle(.secondary)
                    }
                    
                    if viewModel.audiobook.explicit {
                        Image(systemName: "e.square.fill")
                    }
                    if viewModel.audiobook.abridged {
                        Image(systemName: "a.square.fill")
                    }
                    
                    Group {
                        if viewModel.audiobook.narrator != nil || viewModel.audiobook.explicit || viewModel.audiobook.abridged {
                            Text(verbatim: " • ")
                        }
                        
                        Text(viewModel.audiobook.duration.numericDuration())
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .foregroundStyle(.secondary)
                .imageScale(.small)
            }
        }
    }
    
    struct SeriesName: View {
        @Environment(AudiobookViewModel.self) private var viewModel
        
        var body: some View {
            if !viewModel.audiobook.series.isEmpty, let seriesName = viewModel.audiobook.seriesName {
                Group {
                    if viewModel.audiobook.series.count == 1, let series = viewModel.audiobook.series.first {
                        NavigationLink(destination: SeriesLoadView(series: series)){
                            AudiobookView.Header.seriesNameComponent(seriesName)
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
                .padding(.top, 7)
            }
        }
    }
}

extension AudiobookView.Header {
    struct CompactPresentation: View {
        @Environment(AudiobookViewModel.self) private var viewModel
        
        var body: some View {
            VStack(spacing: 0) {
                ItemImage(image: viewModel.audiobook.image, aspectRatio: .none)
                    .padding(.horizontal, 50)
                    .shadow(radius: 30)
                
                SeriesName()
                
                Title(largeFont: false, alignment: .center)
                    .padding(.vertical, 15)
                
                PlayButton(item: viewModel.audiobook)
            }
        }
    }
    
    struct RegularPresentation: View {
        @Environment(AudiobookViewModel.self) private var viewModel
        
        @State private var availableWidth: CGFloat = .zero
        
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
                    ItemImage(image: viewModel.audiobook.image, aspectRatio: .none)
                        .shadow(radius: 30)
                        .frame(width: min(400, (availableWidth - 40) / 2))
                    
                    VStack(alignment: .leading, spacing: 5) {
                        Spacer()
                        
                        SeriesName()
                        Title(largeFont: true, alignment: .leading)
                            .padding(.trailing, 15)
                        
                        Spacer()
                        
                        PlayButton(item: viewModel.audiobook)
                    }
                }
            }
        }
    }
}
