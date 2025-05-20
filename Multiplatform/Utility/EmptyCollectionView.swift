//
//  EmptyCollectionView.swift
//  Multiplatform
//
//  Created by Rasmus Krämer on 23.02.25.
//

import SwiftUI

struct EmptyCollectionView: View {
    var body: some View {
        UnavailableWrapper {
            Inner()
        }
    }
    
    struct Inner: View {
        var body: some View {
            ContentUnavailableView("item.empty", systemImage: "questionmark.folder", description: Text("item.empty.description"))
        }
    }
}

#Preview {
    EmptyCollectionView()
}
