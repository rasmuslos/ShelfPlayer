//
//  ErrorView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct ErrorView: View {
    var body: some View {
        Text("Unable to load")
            .foregroundStyle(.red)
    }
}

#Preview {
    ErrorView()
}
