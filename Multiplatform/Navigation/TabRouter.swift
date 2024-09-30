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
    @State private var libraryPath = NavigationPath()
    
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
                            tab.content(libraryPath: $libraryPath)
                        }
                        .hidden(!isCompact)
                    }
                }
                
                ForEach(libraries) { library in
                    TabSection(library.name) {
                        ForEach(TabValue.tabs(for: library)) { tab in
                            Tab(tab.label, systemImage: tab.image, value: tab) {
                                tab.content(libraryPath: $libraryPath)
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
            .modifier(Navigation.NotificationModifier() { libraryID, audiobookID, authorID, seriesName, seriesID, podcastID, episodeID in
                guard let library = library(for: libraryID) else {
                    return
                }
                
                let previousLibrary = selection?.library
                
                if isCompact {
                    current = library
                }
                
                selection = .audiobookLibrary(library)
                
                Task {
                    if previousLibrary != library {
                        try await Task.sleep(nanoseconds: NSEC_PER_SEC / 2)
                    }
                    
                    if let audiobookID {
                        libraryPath.append(Navigation.AudiobookLoadDestination(audiobookId: audiobookID))
                    }
                    if let authorID {
                        libraryPath.append(Navigation.AuthorLoadDestination(authorId: authorID))
                    }
                    if let seriesName {
                        libraryPath.append(Navigation.SeriesLoadDestination(seriesId: nil, seriesName: seriesName))
                    }
                    if let seriesID {
                        libraryPath.append(Navigation.SeriesLoadDestination(seriesId: seriesID, seriesName: ""))
                    }
                    
                    if let podcastID {
                        if let episodeID {
                            libraryPath.append(Navigation.EpisodeLoadDestination(episodeId: episodeID, podcastId: podcastID))
                        } else {
                            libraryPath.append(Navigation.PodcastLoadDestination(podcastId: podcastID))
                        }
                    }
                }
            })
            .environment(\.libraries, libraries)
            .environment(\.library, selection?.library ?? .init(id: "", name: "", type: .offline, displayOrder: -1))
            .onChange(of: isCompact) {
                if isCompact {
                    current = selection?.library
                } else {
                    current = nil
                }
            }
            .onChange(of: selection?.library) {
                while !libraryPath.isEmpty {
                    libraryPath.removeLast()
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
