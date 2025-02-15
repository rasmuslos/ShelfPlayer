//
//  PodcastView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import SPFoundation

extension PodcastView {
    struct Header: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(\.colorScheme) private var colorScheme
        
        @Environment(PodcastViewModel.self) private var viewModel
        
        private var isLight: Bool? {
            viewModel.dominantColor?.isLight
        }
        private var isRegularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
        var body: some View {
            @Bindable var viewModel = viewModel
            
            ZStack {
                HeroBackground(threshold: isRegularPresentation ? -160 : -335, backgroundColor: viewModel.dominantColor ?? Color(UIColor.secondarySystemBackground), isToolbarVisible: $viewModel.isToolbarVisible)
                
                ViewThatFits {
                    RegularPresentation()
                    CompactPresentation()
                }
            }
            .background {
                Rectangle()
                    .modify {
                        if let dominantColor = viewModel.dominantColor {
                            $0
                                .fill(dominantColor.gradient)
                                .rotationEffect(.degrees(180))
                        } else {
                            $0.fill(Color(UIColor.tertiarySystemBackground))
                        }
                    }
                    .animation(.smooth, value: viewModel.dominantColor)
            }
            .foregroundStyle(isLight == nil ? .primary : isLight! ? Color.black : .white)
            .animation(.smooth, value: viewModel.dominantColor)
        }
    }
}


private struct Title: View {
    @Environment(PodcastViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme
    
    let largeFont: Bool
    let alignment: TextAlignment
    
    var body: some View {
        Text(viewModel.podcast.name)
            .lineLimit(4)
            .font(largeFont ? .title : .headline)
            .multilineTextAlignment(alignment)
        
        if !viewModel.podcast.authors.isEmpty {
            Text(viewModel.podcast.authors, format: .list(type: .and, width: .short))
                .lineLimit(2)
                .foregroundStyle(.thickMaterial)
                .multilineTextAlignment(alignment)
                .font(largeFont ? .title2 : .subheadline)
                .colorScheme(viewModel.dominantColor == nil ? colorScheme == .dark ? .light : .dark : .light)
        }
    }
}
private struct PodcastDescription: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    var body: some View {
        if let description = viewModel.podcast.description {
            Button {
                viewModel.descriptionSheetPresented.toggle()
            } label: {
                HStack {
                    Text(description)
                        .font(.callout)
                        .lineLimit(3)
                    
                    Spacer()
                }
            }
            .buttonStyle(.plain)
        }
    }
}

private struct Additional: View {
    @Environment(PodcastViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme
    
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
        .foregroundStyle(.thickMaterial)
        .colorScheme(viewModel.dominantColor == nil ? colorScheme == .dark ? .light : .dark : .light)
    }
}

private struct CompactPresentation: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ItemImage(item: viewModel.podcast, size: .regular, contrastConfiguration: nil)
                .frame(width: 240)
            
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
            ItemImage(item: viewModel.podcast, size: .large, contrastConfiguration: nil)
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
        .padding(.top, 80)
    }
}
