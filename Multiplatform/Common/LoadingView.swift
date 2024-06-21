//
//  LoadingView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

internal struct LoadingView: View {    
    var body: some View {
        VStack(spacing: 4) {
            ProgressIndicator()
            Text("loading")
        }
        .foregroundStyle(.gray)
    }
}

internal struct ProgressIndicator: View {
    var body: some View {
        ProgressView()
            .tint(.gray)
    }
}

#Preview {
    LoadingView()
}
