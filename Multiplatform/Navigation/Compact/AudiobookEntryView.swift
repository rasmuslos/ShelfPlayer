//
//  AudiobookLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import Defaults
import SPBase

struct AudiobookEntryView: View {
    @Default(.lastActiveAudiobookLibraryTab) var lastActiveAudiobookLibraryTab
    
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
        TabView(selection: $lastActiveAudiobookLibraryTab) {
            Group {
                ListenNowView()
                    .tag(Tab.listenNow)
                SeriesView()
                    .tag(Tab.series)
                LibraryView()
                    .tag(Tab.library)
                
                NavigationStack {
                    SearchView()
                }
                .tag(Tab.search)
                .tabItem {
                    Label("tab.search", systemImage: "magnifyingglass")
                }
            }
            .modifier(NowPlaying.CompactBarModifier())
        }
    }
}

extension AudiobookEntryView {
    enum Tab: Defaults.Serializable, Codable {
        case listenNow
        case series
        case library
        case search
    }
}

extension Defaults.Keys {
    static let lastActiveAudiobookLibraryTab = Key<AudiobookEntryView.Tab>("lastActiveAudiobookLibraryTab", default: .listenNow)
}

