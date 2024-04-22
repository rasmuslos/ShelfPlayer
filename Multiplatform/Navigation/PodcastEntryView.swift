//
//  PodcastLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import Defaults
import SPBase

struct PodcastEntryView: View {
    @Default(.lastActivePodcastLibraryTab) var lastActivePodcastLibraryTab
    
    init() {
        let appearance = UINavigationBarAppearance()
        
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some View {
        TabView(selection: $lastActivePodcastLibraryTab) {
            ListenNowView()
                .tag(Tab.listenNow)
            LatestView()
                .tag(Tab.latest)
            LibraryView()
                .tag(Tab.library)
            SearchView()
                .tag(Tab.search)
        }
    }
}

extension PodcastEntryView {
    enum Tab: Defaults.Serializable, Codable {
        case listenNow
        case latest
        case library
        case search
    }
}

extension Defaults.Keys {
    static let lastActivePodcastLibraryTab = Key<PodcastEntryView.Tab>("lastActivePodcastLibraryTab", default: .listenNow)
}
