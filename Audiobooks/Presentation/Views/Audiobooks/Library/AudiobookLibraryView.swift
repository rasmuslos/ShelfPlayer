//
//  AudiobookLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 03.10.23.
//

import SwiftUI

struct AudiobookLibraryView: View {
    var body: some View {
        TabView {
            HomeView()
            SeriesView()
            LibraryView()
            SearchView()
        }
    }
}

#Preview {
    AudiobookLibraryView()
        .environment(\.libraryId, Library.audiobooksFixture.id)
}
