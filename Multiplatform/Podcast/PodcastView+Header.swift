//
//  PodcastView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation

internal extension PodcastView {
    struct Header: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(PodcastViewModel.self) private var viewModel
        
        private var isLight: Bool? {
            viewModel.dominantColor?.isLight()
        }
        private var isRegularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
        var body: some View {
            @Bindable var viewModel = viewModel
            
            ZStack {
                FullscreenBackground(threshold: isRegularPresentation ? -160 : -280, backgroundColor: viewModel.dominantColor, navigationBarVisible: $viewModel.toolbarVisible)
                
                ViewThatFits {
                    RegularPresentation()
                    CompactPresentation()
                }
            }
            .background {
                if let dominantColor = viewModel.dominantColor {
                    Rectangle()
                        .fill(dominantColor)
                        .transition(.opacity)
                } else {
                    Rectangle()
                        .fill(.background.secondary)
                        .transition(.opacity)
                }
            }
            .foregroundStyle(isLight == nil ? .primary : isLight! ? Color.black : .white)
            .animation(.smooth, value: viewModel.dominantColor)
        }
    }
}


private struct Title: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    let largeFont: Bool
    let alignment: TextAlignment
    
    var body: some View {
        Text(viewModel.podcast.name)
            .lineLimit(4)
            .font(largeFont ? .title : .headline)
            .multilineTextAlignment(alignment)
        
        if let author = viewModel.podcast.author {
            Text(author)
                .font(largeFont ? .title2 : .subheadline)
                .lineLimit(2)
                .multilineTextAlignment(alignment)
        }
    }
}
private struct PodcastDescription: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    var body: some View {
        if let description = viewModel.podcast.description {
            HStack {
                Text(description)
                    .font(.callout)
                    .lineLimit(3)
                
                Spacer()
            }
        }
    }
}

private struct Additional: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    var body: some View {
        HStack {
            HStack(spacing: 3) {
                Label("episodes.count", systemImage: "number")
                    .labelStyle(.iconOnly)
                
                Text(viewModel.episodeCount, format: .number)
            }
            
            if viewModel.podcast.explicit {
                Text(verbatim: "•")
                
                Label("explicit", systemImage: "e.square.fill")
                    .labelStyle(.iconOnly)
            }
            
            if let publishingType = viewModel.podcast.publishingType {
                Text(verbatim: "•")
                
                switch publishingType {
                    case .episodic:
                        Text("podcast.episodic")
                    case .serial:
                        Text("podcast.serial")
                }
            }
            
            if viewModel.podcast.genres.count > 0 {
                Text(verbatim: "•")
                
                Text(viewModel.podcast.genres, format: .list(type: .and, width: .narrow))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .font(.footnote)
    }
}

private struct CompactPresentation: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ItemImage(cover: viewModel.podcast.cover)
                .frame(width: 200)
                .shadow(radius: 8)
            
            VStack(spacing: 4) {
                Title(largeFont: false, alignment: .center)
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            
            Group {
                if let first = viewModel.visible.first {
                    PlayButton(item: first, color: nil)
                        .playButtonSize(.medium)
                } else if viewModel.episodes.isEmpty {
                    PlayButton(item: Episode.placeholder, color: nil)
                        .playButtonSize(.medium)
                        .disabled(true)
                }
            }
            .padding(.bottom, 16)
            
            PodcastDescription()
            
            Additional()
                .padding(.top, 16)
        }
        .padding(.top, 140)
        .padding(.bottom, 12)
        .padding(.horizontal, 20)
    }
}

private struct RegularPresentation: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    var body: some View {
        HStack(spacing: 40) {
            ItemImage(cover: viewModel.podcast.cover)
                .frame(height: 300)
                .hoverEffect(.highlight)
            
            Color.clear
                .frame(minWidth: 250)
                .overlay {
                    VStack(alignment: .leading, spacing: 10) {
                        Additional()
                            .foregroundStyle(.secondary)
                        Title(largeFont: true, alignment: .leading)
                        PodcastDescription()
                    }
                }
        }
        .padding(20)
        .padding(.top, 60)
    }
}
