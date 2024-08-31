//
//  PodcastLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import Defaults
import SPFoundation

struct PodcastTabs: View {
    @Default(.podcastTab) var podcastTab
    
    @State private var navigationPath = NavigationPath()
    
    init() {
        let appearance = UINavigationBarAppearance()
        
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $podcastTab) {
            Group {
                NavigationStack {
                    PodcastListenNowView()
                        .modifier(LibrarySelectModifier())
                }
                .tag(Tab.listenNow)
                .tabItem {
                    Label("tab.home", systemImage: "waveform")
                }
                
                NavigationStack {
                    PodcastLatestView()
                }
                .tag(Tab.latest)
                .tabItem {
                    Label("tab.latest", systemImage: "clock")
                }
                
                NavigationStack(path: $navigationPath) {
                    PodcastLibraryView()
                        .modifier(Navigation.DestinationModifier())
                }
                .tag(Tab.library)
                .tabItem {
                    Label("tab.library", systemImage: "tray.full")
                }
                
                NavigationStack {
                    SearchView()
                }
                .tag(Tab.search)
                .tabItem {
                    Label("tab.search", systemImage: "magnifyingglass")
                }
            }
            .modifier(NowPlaying.CompactTabBarBackgroundModifier())
        }
        .onReceive(NotificationCenter.default.publisher(for: Navigation.navigateNotification)) { notification in
            guard let podcastId = notification.userInfo?["podcastId"] as? String else {
                return
            }
            
            podcastTab = .library
            
            if let episodeId = notification.userInfo?["episodeId"] as? String {
                navigationPath.append(Navigation.EpisodeLoadDestination(episodeId: episodeId, podcastId: podcastId))
            } else {
                navigationPath.append(Navigation.PodcastLoadDestination(podcastId: podcastId))
            }
        }
    }
}

extension PodcastTabs {
    enum Tab: Defaults.Serializable, Codable {
        case listenNow
        case latest
        case library
        case search
    }
}
