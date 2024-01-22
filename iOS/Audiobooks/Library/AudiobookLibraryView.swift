//
//  AudiobookLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI
import SPBase

struct AudiobookLibraryView: View {
    init() {
        let appearance = UINavigationBarAppearance()
        
        appearance.titleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 17, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
        appearance.largeTitleTextAttributes = [.font: UIFont(descriptor: UIFont.systemFont(ofSize: 34, weight: .bold).fontDescriptor.withDesign(.serif)!, size: 0)]
        
        appearance.configureWithTransparentBackground()
        UINavigationBar.appearance().standardAppearance = appearance
        
        appearance.configureWithDefaultBackground()
        UINavigationBar.appearance().compactAppearance = appearance
    }
    
    var body: some View {
        TabView {
            ListenNowView()
            SeriesView()
            LibraryView()
            SearchView()
        }
    }
}

#Preview {
    AudiobookLibraryView()
        .environment(\.libraryId, Library.audiobooksFixture.id)
        .environment(AvailableLibraries(libraries: []))
}
