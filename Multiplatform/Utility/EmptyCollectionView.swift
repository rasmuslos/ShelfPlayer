//
//  EmptyCollectionView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.02.25.
//

import SwiftUI

struct EmptyCollectionView: View {
    var body: some View {
        ContentUnavailableView("collection.empty", systemImage: "questionmark.folder", description: Text("collection.empty.description"))
    }
}
