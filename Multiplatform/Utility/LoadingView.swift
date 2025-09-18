//
//  LoadingView.swift
//  Audiobooks
//
//  Created by Rasmus Krämer on 02.10.23.
//

import SwiftUI

struct LoadingView: View {
    var showOfflineControls = false
    
    var body: some View {
        UnavailableWrapper {
            Inner()
        }
    }
    
    struct Inner: View {
        let symbols = ["pc", "server.rack", "cpu", "memorychip", "hourglass", "zzz"]
        
        var body: some View {
            ContentUnavailableView("loading", systemImage: symbols.randomElement()!)
                .symbolEffect(.pulse)
        }
    }
}

#Preview {
    LoadingView()
}
