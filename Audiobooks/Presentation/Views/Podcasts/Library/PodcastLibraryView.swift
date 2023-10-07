//
//  PodcastLibraryView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 06.10.23.
//

import SwiftUI

struct PodcastLibraryView: View {
    var body: some View {
        TabView {
            Home()
            Latest()
            Library()
            Search()
        }
    }
}

#Preview {
    PodcastLibraryView()
}
