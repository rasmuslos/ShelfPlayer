//
//  OutdatedServerRow.swift
//  ShelfPlayer
//
//  Created by Rasmus Krämer on 23.08.25.
//

import SwiftUI
import ShelfPlayerKit

struct OutdatedServerRow: View {
    let version: String?
    
    var isUsingOutdatedServer: Bool {
        ShelfPlayerKit.isUsingOutdatedServer(version)
    }
    
    var body: some View {
        if isUsingOutdatedServer {
            Text("connection.outdatedServer")
                .foregroundStyle(.orange)
        }
    }
}

#Preview {
    List {
        ForEach(["1.1.1", "2.25.4", "2.26.0", "2.28.0", "3.0.0"], id: \.hashValue) { version in
            Section(version) {
                OutdatedServerRow(version: version)
            }
        }
    }
}
