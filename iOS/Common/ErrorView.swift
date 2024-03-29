//
//  ErrorView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        ContentUnavailableView("error.unavailable.title", systemImage: "xmark.circle", description: Text("error.unavailable.text"))
    }
}

#Preview {
    ErrorView()
}
