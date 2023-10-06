//
//  LoadingView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading")
                .padding()
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    LoadingView()
}
