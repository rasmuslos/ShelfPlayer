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
    
    @State private var selection: TabValue?
    
    private var isCompact: Bool {
        horizontalSizeClass == .compact
    }
    
    var body: some View {
        if !libraries.isEmpty {
            TabView(selection: $selection) {
                if let current {
                    ForEach(tabs(for: current)) { tab in
                        Tab(tab.label, systemImage: tab.image, value: tab) {
                            tab.content
                        }
                        .hidden(!isCompact)
                    }
                }
                
                ForEach(libraries) { library in
                    TabSection(library.name) {
                        ForEach(tabs(for: library)) { tab in
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
            .environment(\.libraries, libraries)
            .modifier(NowPlaying.CompactModifier())
            .modifier(NowPlaying.CompactTabBarBackgroundModifier())
            .onReceive(NotificationCenter.default.publisher(for: SelectLibraryModifier.changeLibraryNotification)) {
                guard let userInfo = $0.userInfo as? [String: String], let libraryID = userInfo["libraryID"] else {
                    return
                }
                
                guard let library = libraries.first(where: { $0.id == libraryID }) else {
                    return
                }
                
                current = library
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
    
    private func tabs(for library: Library) -> [TabValue] {
        switch library.type {
        case .audiobooks:
            [.audiobookHome(library), .audiobookSeries(library), .audiobookAuthors(library), .audiobookLibrary(library), .search(library)]
        case .podcasts:
            [.podcastHome(library), .podcastLatest(library), .podcastLibrary(library)]
        default:
            []
        }
    }
    
    private nonisolated func fetchLibraries() async {
        guard let libraries = try? await AudiobookshelfClient.shared.libraries() else {
            return
        }
        
        let lastActiveLibraryID = Defaults[.lastActiveLibraryID]
        let library = libraries.first { $0.id == lastActiveLibraryID }
        
        await MainActor.withAnimation {
            current = library ?? libraries.first
            self.libraries = libraries
        }
    }
    
    enum TabValue: Identifiable, Hashable {
        case audiobookHome(Library)
        case audiobookSeries(Library)
        case audiobookAuthors(Library)
        case audiobookLibrary(Library)
        
        case podcastHome(Library)
        case podcastLatest(Library)
        case podcastLibrary(Library)
        
        case search(Library)
        
        var id: Self {
            self
        }
        
        var library: Library {
            switch self {
            case .audiobookHome(let library):
                library
            case .audiobookSeries(let library):
                library
            case .audiobookAuthors(let library):
                library
            case .audiobookLibrary(let library):
                library
            case .podcastHome(let library):
                library
            case .podcastLatest(let library):
                library
            case .podcastLibrary(let library):
                library
            case .search(let library):
                library
            }
        }
        
        var label: LocalizedStringKey {
            switch self {
            case .audiobookHome:
                "panel.home"
            case .audiobookSeries:
                "panel.series"
            case .audiobookAuthors:
                "panel.authors"
            case .audiobookLibrary:
                "panel.library"
                
            case .podcastHome:
                "panel.home"
            case .podcastLatest:
                "panel.latest"
            case .podcastLibrary:
                "panel.library"
                
            case .search:
                "panel.search"
            }
        }
        
        var image: String {
            switch self {
            case .audiobookHome:
                "play.house.fill"
            case .audiobookSeries:
                "rectangle.grid.3x2.fill"
            case .audiobookAuthors:
                "person.2.fill"
            case .audiobookLibrary:
                "books.vertical.fill"
                
            case .podcastHome:
                "music.note.house.fill"
            case .podcastLatest:
                "calendar.badge.clock"
            case .podcastLibrary:
                "square.split.2x2.fill"
                
            case .search:
                "magnifyingglass"
            }
        }
        
        @ViewBuilder
        var content: some View {
            NavigationStack {
                switch self {
                case .audiobookHome:
                    AudiobookHomePanel()
                case .audiobookSeries:
                    AudiobookSeriesPanel()
                case .audiobookAuthors:
                    AudiobookAuthorsPanel()
                case .audiobookLibrary:
                    AudiobookLibraryPanel()
                    
                case .podcastHome:
                    PodcastHomePanel()
                case .podcastLatest:
                    PodcastLatestPanel()
                case .podcastLibrary:
                    PodcastLibraryPanel()
                    
                case .search:
                    SearchView()
                }
            }
            .environment(\.library, library)
        }
    }
}

@available(iOS 18, *)
#Preview {
    TabRouter()
        .environment(NowPlaying.ViewModel())
}
