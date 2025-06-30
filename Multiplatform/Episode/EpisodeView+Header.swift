//
//  EpisodeView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

extension EpisodeView {
    struct Header: View {
        @Environment(\.horizontalSizeClass) private var horizontalSizeClass
        @Environment(EpisodeViewModel.self) private var viewModel
        
        private var isRegularPresentation: Bool {
            horizontalSizeClass == .regular
        }
        
        var body: some View {
            @Bindable var viewModel = viewModel
            
            ZStack {
                HeroBackground(threshold: isRegularPresentation ? -100 : -280, backgroundColor: viewModel.dominantColor?.opacity(0.9), isToolbarVisible: $viewModel.toolbarVisible)
                
                Group {
                    ViewThatFits {
                        RegularPresentation()
                        CompactPresentation()
                    }
                }
                .background {
                    LinearGradient(colors: [(viewModel.dominantColor ?? .clear).opacity(0.9), .secondary.opacity(0.1)], startPoint: .top, endPoint: .bottom)
                        .animation(.smooth, value: viewModel.dominantColor)
                }
            }
        }
    }
}


private struct Eyebrow: View {
    @Environment(EpisodeViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        HStack(spacing: 0) {
            if let releaseDate = viewModel.episode.releaseDate {
                Text(releaseDate, style: .date)
                Text(verbatim: " • ")
                    .accessibilityHidden(true)
            }
            
            Text(viewModel.episode.duration, format: .duration)
        }
        .font(.caption.smallCaps())
        .foregroundStyle(.ultraThinMaterial)
        .colorScheme(colorScheme == .dark ? .light : .dark)
    }
}

private struct Title: View {
    @Environment(EpisodeViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.library) private var library
    
    let alignment: HorizontalAlignment
    
    private var isLight: Bool {
        colorScheme == .light
    }
    
    var body: some View {
        VStack(alignment: alignment, spacing: 4) {
            Text(viewModel.episode.name)
                .font(.title3)
                .bold()
                .lineLimit(4)
                .multilineTextAlignment(alignment.textAlignment)
            
            HStack {
                NavigationLink(destination: ItemLoadView(viewModel.episode.podcastID)) {
                    HStack(spacing: 4) {
                        Text(viewModel.episode.podcastName)
                        
                        Label(ItemIdentifier.ItemType.podcast.viewLabel, systemImage: "chevron.right.circle")
                            .labelStyle(.iconOnly)
                            .font(.caption2)
                    }
                }
                .lineLimit(1)
                .font(.footnote)
                .foregroundStyle(.ultraThinMaterial)
                .colorScheme(isLight ? .dark : .light)
                .buttonStyle(.plain)
                .hoverEffect()
                
                if alignment == .leading {
                    Spacer()
                }
            }
        }
    }
}

private struct TypeLabel: View {
    @Environment(EpisodeViewModel.self) private var viewModel
    @Environment(\.colorScheme) private var colorScheme
    
    private var isLight: Bool {
        colorScheme == .light
    }
    
    var body: some View {
        Group {
            if viewModel.episode.type == .trailer {
                Text("item.trailer")
            } else if viewModel.episode.type == .bonus {
                Text("item.bonus")
            }
        }
        .font(.caption)
        .padding(.top, 8)
        .foregroundStyle(.ultraThinMaterial)
        .colorScheme(isLight ? .dark : .light)
    }
}

private struct CompactPresentation: View {
    @Environment(EpisodeViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ItemImage(item: viewModel.episode, size: .regular, contrastConfiguration: nil)
                .frame(width: 180)
            
            Eyebrow()
                .padding(.top, 8)
            
            Title(alignment: .center)
                .padding(.top, 8)
                .padding(.bottom, 16)
            
            PlayButton(item: viewModel.episode)
            
            TypeLabel()
        }
        .padding(.top, 120)
        .padding(.bottom, 20)
        .padding(.horizontal, 20)
    }
}

private struct RegularPresentation: View {
    @Environment(EpisodeViewModel.self) private var viewModel
    
    var body: some View {
        HStack(spacing: 20) {
            ItemImage(item: viewModel.episode, size: .large, contrastConfiguration: nil)
                .frame(width: 225)
            
            Color.clear
                .frame(minWidth: 360)
                .overlay {
                    VStack(alignment: .leading) {
                        Spacer()
                        
                        Eyebrow()
                        Title(alignment: .leading)
                        
                        Spacer()
                        
                        PlayButton(item: viewModel.episode)
                        
                        TypeLabel()
                    }
                }
        }
        .padding(20)
        .padding(.top, 80)
    }
}
