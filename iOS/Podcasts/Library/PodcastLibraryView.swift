//
//  PodcastLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI
import SPBase

struct PodcastLibraryView: View {
    init() {
        let appearance = UINavigationBarAppearance()
        
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some View {
        TabView {
            ListenNowView()
            LatestEpisodesView()
            LibraryView()
            SearchView()
        }
    }
}
