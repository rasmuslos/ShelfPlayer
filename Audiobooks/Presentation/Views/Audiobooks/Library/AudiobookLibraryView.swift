//
//  AudiobookLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

struct AudiobookLibraryView: View {
    let library: Library
    
    var body: some View {
        TabView {
            HomeView()
            LibraryView()
            SeriesView()
            SearchView()
        }
    }
}

#Preview {
    AudiobookLibraryView(library: Library.audiobooksFixture)
        .environment(\.libraryId, Library.audiobooksFixture.id)
}
