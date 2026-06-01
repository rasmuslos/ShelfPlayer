//
//  EmptyCollectionView.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.02.25.
//

import SwiftUI

struct EmptyCollectionView: View {
    var systemImage = "questionmark.folder"

    var body: some View {
        UnavailableWrapper {
            Inner(systemImage: systemImage)
        }
    }

    struct Inner: View {
        var systemImage = "questionmark.folder"

        var body: some View {
            ContentUnavailableView("item.empty", systemImage: systemImage, description: Text("item.empty.description"))
        }
    }
}

#Preview {
    EmptyCollectionView()
}
