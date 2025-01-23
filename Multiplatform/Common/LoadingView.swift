//
//  LoadingView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct LoadingView: View {
    let symbols = ["pc", "server.rack", "cpu", "memorychip"]
    
    var body: some View {
        UnavailableWrapper {
            ContentUnavailableView("loading", systemImage: symbols.randomElement()!)
                .symbolEffect(.pulse)
        }
    }
}

struct ProgressIndicator: View {
    var tint: Color = .gray
    
    var body: some View {
        ProgressView()
            .tint(tint)
    }
}

#Preview {
    LoadingView()
}
