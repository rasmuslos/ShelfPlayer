//
//  PodcastView+Header.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 08.10.23.
//

import SwiftUI
import ShelfPlayback

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
                            $0
                                .fill(Color(UIColor.secondarySystemBackground))
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
    
    private var isLight: Bool {
        if let isLight = viewModel.dominantColor?.isLight {
            return isLight
        }
        
        return colorScheme == .light
    }
    
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
                .colorScheme(isLight ? .dark : .light)
        }
    }
}
private struct PodcastDescription: View {
    @Environment(PodcastViewModel.self) private var viewModel
    @Environment(Satellite.self) private var satellite
    
    var body: some View {
        if let description = viewModel.podcast.description {
            Button {
                satellite.present(.description(viewModel.podcast))
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
    
    private var isLight: Bool {
        if let isLight = viewModel.dominantColor?.isLight {
            return isLight
        }
        
        return colorScheme == .light
    }
    
    var body: some View {
        HStack {
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Image(systemName: "number")
                Text(viewModel.episodeCount, format: .number)
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("item.count.episodes \(viewModel.episodeCount)")
            
            if viewModel.podcast.explicit {
                Label("item.explicit", systemImage: "e.square.fill")
                    .labelStyle(.iconOnly)
            }
            
            if let publishingType = viewModel.podcast.publishingType {
                Text(verbatim: "•")
                    .accessibilityHidden(true)
                
                Text(publishingType.label)
            }
            
            if viewModel.podcast.genres.count > 0 {
                Text(verbatim: "•")
                    .accessibilityHidden(true)
                
                Text(viewModel.podcast.genres, format: .list(type: .and, width: .narrow))
                    .lineLimit(1)
            }
            
            Spacer()
        }
        .font(.footnote)
        .foregroundStyle(.thickMaterial)
        .colorScheme(isLight ? .dark : .light)
    }
}

private struct PlayFirstEpisodeButton: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    var body: some View {
        Group {
            if let first = viewModel.visible.first {
                PlayButton(item: first)
                    .playButtonSize(.medium)
            } else if viewModel.episodes.isEmpty {
                PlayButton(item: Episode.placeholder)
                    .playButtonSize(.medium)
                    .disabled(true)
            }
        }
    }
}

private struct CompactPresentation: View {
    @Environment(PodcastViewModel.self) private var viewModel
    
    var body: some View {
        VStack(spacing: 0) {
            ItemImage(item: viewModel.podcast, size: .regular, contrastConfiguration: nil)
                .frame(width: 240)
                .shadow(radius: 16)
            
            VStack(spacing: 4) {
                Title(largeFont: false, alignment: .center)
            }
            .padding(.top, 16)
            .padding(.bottom, 16)
            
            PlayFirstEpisodeButton()
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
            
            Color.clear
                .frame(minWidth: 250)
                .overlay {
                    VStack(alignment: .leading, spacing: 10) {
                        Additional()
                            .foregroundStyle(.secondary)
                        Title(largeFont: true, alignment: .leading)
                        PodcastDescription()
                        PlayFirstEpisodeButton()
                    }
                }
        }
        .padding(20)
        .padding(.top, 80)
    }
}

extension Podcast.PodcastType {
    var label: String {
        switch self {
            case .episodic: String(localized: "item.publishing.episodic")
            case .serial: String(localized: "item.publishing.serial")
        }
    }
}

#if DEBUG
#Preview {
    TabView {
        Tab(String("ABC"), systemImage: "command") {
            List {
                Image("Logo")
                    .resizable()
                    .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .modify {
                        if #available(iOS 26, *) {
                            $0
                                .backgroundExtensionEffect()
                        } else {
                            $0
                        }
                    }
            }
            .listStyle(.plain)
        }
    }
    .tabViewStyle(.sidebarAdaptable)
    .previewEnvironment()
}
#endif
