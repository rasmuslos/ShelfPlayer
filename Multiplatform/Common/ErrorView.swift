//
//  ErrorView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

internal struct ErrorView: View {
    var body: some View {
        UnavailableWrapper {
            ContentUnavailableView("error.unavailable.title", systemImage: "xmark", description: Text("error.unavailable.text"))
        }
    }
}

#Preview {
    ErrorView()
}
