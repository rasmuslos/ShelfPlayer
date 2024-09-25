//
//  TabRouter.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

@available(iOS 18, *)
internal struct TabRouter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.lastTabValue) private var selection
    @State private var current: Library? {
        didSet {
            let appearance = UINavigationBarAppearance()
            
            if current?.type == .audiobooks && Defaults[.useSerifFont] {
                appearance.titleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 17, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
                appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
            }
            
            appearance.configureWithTransparentBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            
            appearance.configureWithDefaultBackground()
            UINavigationBar.appearance().compactAppearance = appearance
        }
    }
    
    @State private var libraries: [Library] = []
    
    private func library(for id: String) -> Library? {
        libraries.first(where: { $0.id == id })
    }
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        if !libraries.isEmpty {
            TabView(selection: $selection) {
                if let current {
                    ForEach(TabValue.tabs(for: current)) { tab in
                        Tab(tab.label, systemImage: tab.image, value: tab) {
                            tab.content
                        }
                        .hidden(!isCompact)
                    }
                }
                
                ForEach(libraries) { library in
                    TabSection(library.name) {
                        ForEach(TabValue.tabs(for: library)) { tab in
                            Tab(tab.label, systemImage: tab.image, value: tab) {
                                tab.content
                            }
                        }
                    }
                    .hidden(isCompact)
                }
            }
            .tabViewStyle(.sidebarAdaptable)
            .tabViewSidebarBottomBar {
                Button {
                    NotificationCenter.default.post(name: SelectLibraryModifier.changeLibraryNotification, object: nil, userInfo: [
                        "offline": true,
                    ])
                } label: {
                    Label("offline.enable", systemImage: "network.slash")
                }
            }
            .id(current)
            .modifier(NowPlaying.CompactModifier())
            .modifier(Navigation.DestinationModifier())
            .modifier(Navigation.NotificationModifier(
                navigateAudiobook: {
                    guard let library = library(for: $1) else {
                        return
                    }
                    
                    let value = TabValue.audiobookLibrary(library)
                    selection = value
                    NavigationState.shared[value].append(Navigation.AudiobookLoadDestination(audiobookId: $0))
                    
                    print(library)
                }, navigateAuthor: {
                    guard let library = library(for: $1) else {
                        return
                    }
                    
                    let value = TabValue.audiobookLibrary(library)
                    selection = value
                    NavigationState.shared[value].append(Navigation.AuthorLoadDestination(authorId: $0))
                }, navigateSeries: {
                    guard let library = library(for: $1) else {
                        return
                    }
                    
                    let value = TabValue.audiobookLibrary(library)
                    selection = value
                    NavigationState.shared[value].append(Navigation.SeriesLoadDestination(seriesName: $0))
                }, navigatePodcast: {
                    guard let library = library(for: $1) else {
                        return
                    }
                    
                    let value = TabValue.podcastLibrary(library)
                    selection = value
                    NavigationState.shared[value].append(Navigation.PodcastLoadDestination(podcastId: $0))
                }, navigateEpisode: {
                    guard let library = library(for: $2) else {
                        return
                    }
                    
                    let value = TabValue.podcastLibrary(library)
                    selection = value
                    NavigationState.shared[value].append(Navigation.EpisodeLoadDestination(episodeId: $0, podcastId: $1))
                }))
            .environment(\.libraries, libraries)
            .environment(\.library, selection?.library ?? .init(id: "", name: "", type: .offline, displayOrder: -1))
            .onChange(of: isCompact) {
                if isCompact {
                    current = selection?.library
                } else {
                    current = nil
                }
            }
            .onReceive(NotificationCenter.default.publisher(for: SelectLibraryModifier.changeLibraryNotification)) {
                guard let userInfo = $0.userInfo as? [String: String], let libraryID = userInfo["libraryID"] else {
                    return
                }
                
                guard let library = libraries.first(where: { $0.id == libraryID }) else {
                    return
                }
                
                if isCompact {
                    current = library
                }
                if library.type == .audiobooks {
                    selection = .audiobookHome(library)
                } else if library.type == .podcasts {
                    selection = .podcastHome(library)
                }
            }
        } else {
            LoadingView()
                .task {
                    await fetchLibraries()
                }
                .refreshable {
                    await fetchLibraries()
                }
        }
    }
    
    private nonisolated func fetchLibraries() async {
        guard let libraries = try? await AudiobookshelfClient.shared.libraries() else {
            return
        }
        
        await MainActor.withAnimation {
            self.libraries = libraries
            
            if isCompact {
                current = selection?.library ?? libraries.first
            }
        }
    }
}

@available(iOS 18, *)
#Preview {
    TabRouter()
        .environment(NowPlaying.ViewModel())
}
