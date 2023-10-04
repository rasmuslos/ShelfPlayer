//
//  AuthorUnavailableView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 04.10.23.
//

import SwiftUI

struct AuthorUnavailableView: View {
    var body: some View {
        ContentUnavailableView("Author unavailable", systemImage: "person", description: Text("Please ensure that you are connected to the internet"))
    }
}

#Preview {
    AuthorUnavailableView()
}
