//
//  LoadingView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct LoadingView: View {
    var body: some View {
        ProgressView {
            Text("loading")
        }
    }
}

#Preview {
    LoadingView()
}
