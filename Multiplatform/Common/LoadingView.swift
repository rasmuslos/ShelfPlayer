//
//  LoadingView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

internal struct LoadingView: View {
    let symbols = ["pc", "server.rack", "cpu", "memorychip"]
    
    var body: some View {
        UnavailableWrapper {
            ContentUnavailableView("loading", systemImage: symbols.randomElement()!)
                .symbolEffect(.pulse)
        }
    }
}

internal struct ProgressIndicator: View {
    var tint: Color = .gray
    
    var body: some View {
        #if DEBUG
        Image(systemName: "rainbow")
            .font(.title3)
            .symbolRenderingMode(.multicolor)
            .symbolEffect(.variableColor.iterative.dimInactiveLayers)
        #else
        ProgressView()
            .tint(tint)
        #endif
    }
}

#Preview {
    LoadingView()
}
