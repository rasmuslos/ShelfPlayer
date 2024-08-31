//
//  AudiobookLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import Defaults
import SPFoundation

struct AudiobookTabs: View {
    @Default(.audiobookTab) var audiobookTab
    
    @State private var navigationPath = NavigationPath()
    
    init() {
        if Defaults[.useSerifFont] {
            let appearance = UINavigationBarAppearance()
            
            appearance.titleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 17, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
            appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
            
            appearance.configureWithTransparentBackground()
            UINavigationBar.appearance().standardAppearance = appearance
            
            appearance.configureWithDefaultBackground()
            UINavigationBar.appearance().compactAppearance = appearance
        }
    }
    
    var body: some View {
        TabView(selection: $audiobookTab) {
            Group {
                NavigationStack {
                    AudiobookListenNowView()
                        .modifier(LibrarySelectModifier())
                }
                .tag(Tab.listenNow)
                .tabItem {
                    Label("tab.home", systemImage: "bookmark.fill")
                }
                
                NavigationStack {
                    AudiobookSeriesView()
                }
                .tag(Tab.series)
                .tabItem {
                    Label("tab.series", systemImage: "books.vertical.fill")
                }
                
                
                NavigationStack(path: $navigationPath) {
                    AudiobookLibraryView()
                        .modifier(Navigation.DestinationModifier())
                }
                .tag(Tab.library)
                .tabItem {
                    Label("tab.library", systemImage: "book.fill")
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
            audiobookTab = .library
            
            if let audiobookId = notification.userInfo?["audiobookId"] as? String {
                navigationPath.append(Navigation.AudiobookLoadDestination(audiobookId: audiobookId))
            } else if let authorId = notification.userInfo?["authorId"] as? String {
                navigationPath.append(Navigation.AuthorLoadDestination(authorId: authorId))
            } else if let seriesName = notification.userInfo?["seriesName"] as? String {
                navigationPath.append(Navigation.SeriesLoadDestination(seriesName: seriesName))
            }
        }
    }
}

extension AudiobookTabs {
    enum Tab: Defaults.Serializable, Codable {
        case listenNow
        case series
        case library
        case search
    }
}

