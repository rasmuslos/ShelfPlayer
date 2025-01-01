//
//  LegacyRouter.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.09.24.
//

import Foundation
import SwiftUI
import Defaults
import ShelfPlayerKit

@available(iOS, deprecated: 18.0, message: "Use <code>TabRouter</code> instead.")
internal struct LegacyRouter: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @Default(.lastTabValue) private var selection
    @State private var current: Library?
    
    @State private var libraries: [Library] = []
    @State private var libraryPath = NavigationPath()
    
    private func library(for id: String) -> Library? {
        libraries.first(where: { $0.id == id })
    }
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    @ViewBuilder
    private var loadingPresentation: some View {
        LoadingView()
            .task {
                await fetchLibraries()
            }
            .refreshable {
                await fetchLibraries()
            }
    }
    
    var body: some View {
        if !libraries.isEmpty {
            Group {
                if isCompact {
                    if let current {
                        Tabs(current: current, selection: $selection, libraryPath: $libraryPath)
                    } else {
                        loadingPresentation
                    }
                } else {
                    Sidebar(libraries: libraries, selection: $selection, libraryPath: $libraryPath)
                }
            }
            .id(current)
            .modifier(NowPlaying.CompactModifier())
            /*
            .modifier(Navigation.NotificationModifier() { libraryID, audiobookID, authorName, authorID, seriesName, seriesID, podcastID, episodeID in
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
                    if let authorName {
                        libraryPath.append(Navigation.AuthorLoadDestination(authorName: authorName))
                    }
                    if let authorID {
                        libraryPath.append(Navigation.AuthorLoadDestination(authorId: authorID))
                    }
                    if let seriesName {
                        libraryPath.append(Navigation.SeriesLoadDestination(seriesName: seriesName))
                    }
                    if let seriesID {
                        libraryPath.append(Navigation.SeriesLoadDestination(seriesId: seriesID))
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
             */
            .environment(\.libraries, libraries)
            // .environment(\.library, selection?.library ?? .init(id: "", name: "", type: .offline, displayOrder: -1))
            .onChange(of: isCompact) {
                if isCompact {
                    current = selection?.library ?? libraries.first
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
            .onReceive(Search.shared.searchPublisher) { (library, search) in
                guard let library else {
                    return
                }
                
                if current == library {
                    return
                }
                
                if isCompact {
                    current = library
                }
                if library.type == .audiobooks {
                    selection = .search(library)
                } else if library.type == .podcasts {
                    selection = .podcastLibrary(library)
                }
                
                Task {
                    try await Task.sleep(for: .milliseconds(500))
                    Search.shared.emit(library: library, search: search)
                }
            }
        } else {
            loadingPresentation
        }
    }
    
    private nonisolated func fetchLibraries() async {
        /*
        guard let libraries = try? await AudiobookshelfClient.shared.libraries() else {
            return
        }
        
        await MainActor.withAnimation {
            current = selection?.library ?? libraries.first
            self.libraries = libraries
        }
         */
    }
}
