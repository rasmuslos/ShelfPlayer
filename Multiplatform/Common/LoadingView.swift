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
            ProgressIndicator()
            Text("loading")
        }
        .foregroundStyle(.gray)
    }
}

struct ProgressIndicator: View {
    var body: some View {
        ProgressView()
            .tint(.gray)
    }
}

#Preview {
    LoadingView()
}
